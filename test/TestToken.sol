// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20Minimal } from "v4-core/src/interfaces/external/IERC20Minimal.sol";

/// @notice Simple ERC20 for testing, implements IERC20Minimal + symbol/name/decimals.
contract TestERC20 is IERC20Minimal {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balanceOf[msg.sender] = initialSupply;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        uint256 balance = balanceOf[msg.sender];
        require(balance >= amount, "INSUFFICIENT_BALANCE");
        balanceOf[msg.sender] = balance - amount;
        balanceOf[to] = balanceOf[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        override
        returns (bool)
    {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "ALLOWANCE_EXCEEDED");
        allowance[from][msg.sender] = allowed - amount;

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount, "INSUFFICIENT_BALANCE");
        balanceOf[from] = fromBalance - amount;
        balanceOf[to] = balanceOf[to] + amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] = balanceOf[to] + amount;
    }
}
