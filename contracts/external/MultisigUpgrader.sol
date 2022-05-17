// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ECDSA } from '@solidstate/contracts/cryptography/ECDSA.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { IMultisigUpgrader } from "contracts/interfaces/IMultisigUpgrader.sol";
import { RepositoryStorage } from "contracts/storage/RepositoryStorage.sol";
import { GovernanceStorage } from "contracts/storage/GovernanceStorage.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

contract MultisigUpgrader is IMultisigUpgrader {
    using AddressUtils for address;
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;
    using RepositoryStorage for RepositoryStorage.Layout;
    using GovernanceStorage for GovernanceStorage.Layout;

    struct Parameters {
        address payable target;
        bytes data;
        uint256 value;
        bool delegate;
    }

    struct Signature {
        bytes data;
        uint256 nonce;
    }

    address public diamond;
    uint256 public quorum;
    EnumerableSet.AddressSet signers;
    mapping(address => mapping(uint256 => bool)) nonces;


    function initialize(address _diamond, address[] memory _signers, uint256 _quorum) external {
        require(diamond == address(0) && _diamond != address(0), "Multisig: already initialized.");
        for (uint i; i < _signers.length; i++) {
            require(signers.length() < 256, 'MultisigUpgrader: signer limit reached');
            require(signers.add(_signers[i]), 'MultisigUpgrader: failed to add signer');
        }
        require(_quorum <= signers.length(), 'MultisigWallet: insufficient signers to meet quorum');
        quorum = _quorum;
        diamond = _diamond;
    }

    /**
     * @inheritdoc IMultisigUpgrader
     */
    function execute(uint256 _proposalId) external { // this wallet can make 1 upgrade
        GovernanceStorage.Proposal storage p = GovernanceStorage.layout().proposals[_proposalId];
        address team = p.proposalContract;
        require(address(this) == MultisigUpgrader(payable(team)).diamond(), 
        "Multisig: sender should be Diamond");
        RepositoryStorage.layout().upgradeCredits[team] += 1;
    }

    function _isInvalidNonce(
        address account,
        uint256 nonce
    ) internal view returns (bool) {
        return nonces[account][nonce];
    }

    function _setInvalidNonce(
        address account,
        uint256 nonce
    ) internal {
        nonces[account][nonce] = true;
    }

    function _isSigner(address account)
        internal
        view
        returns (bool)
    {
        return signers.contains(account);
    }

    function getSigners() external view returns (address[] memory) {
        return _getSigners();
    }

    function _getSigners() internal view returns (address[] memory) {
        uint length = signers.length();
        address[] memory _signers = new address[](length);
        for (uint i; i < length; i++) {
            _signers[i] = signers.at(i);
        }
        return _signers;
    }

    receive() external payable virtual {}

    /**
     * @notice verify signatures and execute "call" or "delegatecall" with given parameters
     * @dev message parameters must be included in signature
     * @param parameters structured call parameters (target, data, value, delegate)
     * @param signatures array of structured signature data (signature, nonce)
     */
    function verifyAndExecute(
        Parameters memory parameters,
        Signature[] memory signatures
    ) public payable virtual returns (bytes memory) {
        _verifySignatures(
            abi.encodePacked(
                parameters.target,
                parameters.data,
                parameters.value,
                parameters.delegate
            ),
            signatures
        );

        return _executeCall(parameters);
    }

    /**
     * @notice execute low-level "call" or "delegatecall"
     * @param parameters structured call parameters (target, data, value, delegate)
     */
    function _executeCall(Parameters memory parameters)
        internal
        virtual
        returns (bytes memory)
    {
        bool success;
        bytes memory returndata;

        if (parameters.delegate) {
            require(
                parameters.value == msg.value,
                'MultisigUpgrader: delegatecall value must match signed amount'
            );
            (success, returndata) = parameters.target.delegatecall(
                parameters.data
            );
        } else {
            (success, returndata) = parameters.target.call{
                value: parameters.value
            }(parameters.data);
        }

        if (success) {
            return returndata;
        } else {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @notice verify eligibility of set of signatures to execute transaction
     * @dev message value and call type must be included in signature
     * @param data packed data payload
     * @param signatures array of structured signature data (signature, nonce)
     */
    function _verifySignatures(bytes memory data, Signature[] memory signatures)
        internal
        virtual
    {

        require(
            signatures.length >= quorum,
            'MultisigUpgrader: quorum not reached'
        );

        uint256 signerBitmap;

        unchecked {
            for (uint256 i; i < signatures.length; i++) {
                Signature memory signature = signatures[i];

                address signer = keccak256(
                    abi.encodePacked(data, signature.nonce, address(this))
                ).toEthSignedMessageHash().recover(signature.data);

                uint256 index = signers.indexOf(signer);

                require(
                    index < 256,
                    'MultisigUpgrader: recovered signer not authorized'
                );

                require(
                    !_isInvalidNonce(signer, signature.nonce),
                    'MultisigUpgrader: invalid nonce'
                );

                _setInvalidNonce(signer, signature.nonce);

                uint256 shift = 1 << index;

                require(
                    signerBitmap & shift == 0,
                    'MultisigUpgrader: signer cannot sign more than once'
                );

                signerBitmap |= shift;
            }
        }
    }
}
