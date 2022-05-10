// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from "@solidstate/contracts/token/ERC20/ERC20.sol";
import { ERC20BaseStorage } from "@solidstate/contracts/token/ERC20/base/ERC20BaseStorage.sol";
import { GovernanceStorage } from "contracts/storage/GovernanceStorage.sol";

contract Token is ERC20 {
    using ERC20BaseStorage for ERC20BaseStorage.Layout;

    /// @dev most of these overriding functions may not be necessary

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balanceOf(account);
    }

    function allowance(address holder, address spender)
        public
        view
        virtual override
        returns (uint256)
    {
        return ERC20BaseStorage.layout().allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = ERC20BaseStorage.layout().allowances[holder][
            msg.sender
        ];
        require(currentAllowance >= amount,
        "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(holder, msg.sender, currentAllowance - amount);
        }
        _transfer(holder, recipient, amount);
        return true;
    }

    /// @dev these transfer functions also handle locking tokens while there's a vote
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(holder != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(holder, recipient, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 holderBalance = l.balances[holder];
        require(holderBalance >= amount,
        "ERC20: transfer amount exceeds balance");
        unchecked {
            l.balances[holder] = holderBalance - amount;
        }
        l.balances[recipient] += amount;

        emit Transfer(holder, recipient, amount);

        GovernanceStorage.Layout storage gs = GovernanceStorage.layout();
        uint24[] storage proposalIds = gs.votedProposalIds[holder];
        uint index = proposalIds.length;
        while(index > 0) {
            index--;
            GovernanceStorage.Proposal storage proposalStorage = gs.proposals[proposalIds[index]];
            require(block.timestamp > proposalStorage.deadline, "Token: Cannot transfer during vote");
            require(msg.sender != proposalStorage.proposer || proposalStorage.executed, "Token: Proposal must execute first.");
            proposalIds.pop();
        }
    }

    function increaseAllowance(address spender, uint256 amount)
        public
        virtual override
        returns (bool)
    {
        unchecked {
            mapping(address => uint256) storage allowances = ERC20BaseStorage
                .layout()
                .allowances[msg.sender];

            uint256 allowance = allowances[spender];
            require(allowance + amount >= allowance,
            "ERC20Extended: excessive allowance");

            _approve(
                msg.sender,
                spender,
                allowances[spender] = allowance + amount
            );

            return true;
        }
    }

    function decreaseAllowance(address spender, uint256 amount)
        public
        virtual override
        returns (bool)
    {
        unchecked {
            mapping(address => uint256) storage allowances = ERC20BaseStorage
                .layout()
                .allowances[msg.sender];

            uint256 allowance = allowances[spender];
            require(amount <= allowance,
            "ERC20Extended: insufficient allowance");

            _approve(
                msg.sender,
                spender,
                allowances[spender] = allowance - amount
            );

            return true;
        }
    }

}