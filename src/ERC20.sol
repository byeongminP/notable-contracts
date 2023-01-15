// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title ERC20 Contract
 * @author Byeong Min Park
 * @dev Implementation of ERC20 from scratch.
 */
contract ERC20 {
    // Variables
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    // ERC20 logic
    function approve(address spender, uint256 value)
        public
        virtual
        returns (bool success)
    {
        require(spender != address(0), "cannot approve zero address");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool success)
    {
        require(to != address(0), "cannot transfer to zero address");

        uint256 fromBalance = balanceOf[msg.sender];
        require(fromBalance >= amount, "transfer amount exceeds balance");

        balanceOf[msg.sender] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool success) {
        require(from != address(0), "cannot transfer from zero address");
        require(to != address(0), "cannot transfer to zero address");

        uint256 fromAllowance = allowance[from][msg.sender];
        require(fromAllowance >= amount, "transfer amount exceeds allowance");
        if (fromAllowance != type(uint256).max) {
            allowance[from][msg.sender] = fromAllowance - amount;
        }

        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount, "transfer amount exceeds balance");

        balanceOf[from] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    // Mint/Burn logic
    function mint(address to, uint256 amount) public virtual {
        totalSupply += amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) public virtual {
        balanceOf[from] -= amount;
        unchecked {
            totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    // Events
    event Transfer(address indexed from, address indexed to, uint256 _value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 _value
    );
}
