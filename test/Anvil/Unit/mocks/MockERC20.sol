// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MockERC20 {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  string public name = "Mock Token";
  string public symbol = "MOCK";
  uint8 public decimals = 18;

  constructor(uint256 initialSupply) {
    _mint(msg.sender, initialSupply);
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public returns (bool) {
    require(
      _allowances[sender][msg.sender] >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(
      _balances[sender] >= amount,
      "ERC20: transfer amount exceeds balance"
    );

    _balances[sender] -= amount;
    _balances[recipient] += amount;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");
    _balances[account] += amount;
  }
}
