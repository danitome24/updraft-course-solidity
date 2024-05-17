//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./SimpleStorage.sol";

contract StorageFactory {

    SimpleStorage[] listOfSimpleStorageContracts;

    function createSimpleStorageContract() public {
        SimpleStorage newSimpleStorageContract = new SimpleStorage();

        listOfSimpleStorageContracts.push(newSimpleStorageContract);
    }

    function sfStore(uint256 _simpleStorageIndex, uint256 _favoriteNumber) public {
        SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[_simpleStorageIndex];
        mySimpleStorage.store(_favoriteNumber);
    }

    function sfRetrieve(uint256 _sfIndex) public view returns(uint256) {
        SimpleStorage mySimpleStorage = listOfSimpleStorageContracts[_sfIndex];
        return mySimpleStorage.retrieve();
    }

}
