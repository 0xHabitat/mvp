/* global ethers */

const action = { add: 0, replace: 1, remove: 2 }

function createAddFacetCut(contracts) {
  let cuts = [];
  for (const contract of contracts) {
    cuts.push(
      {
        target: contract.address,
        action: action.add,
        selectors: Object.keys(contract.interface.functions)
        // .filter((fn) => fn != 'init()')
        .map((fn) => contract.interface.getSighash(fn),
        ),
      },
    );
  }
  return cuts;
}

exports.createAddFacetCut = createAddFacetCut