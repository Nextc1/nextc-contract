// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract CarbonCredit is ERC20, ERC20Burnable, ERC20Pausable, AccessManaged, ERC20Permit {
    constructor(address initialAuthority)
        ERC20("Carbon Credit", "CC")
        AccessManaged(initialAuthority)
        ERC20Permit("Carbon Credit")
    {}

    

    function unpause() public restricted {
        _unpause();
    }

    function mint(address to, uint256 amount) public restricted {
        _mint(to, amount);
    }

    

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}