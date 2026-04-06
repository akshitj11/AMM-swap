# @version ^0.3.10
name: String[64]
symbol: String[32]
decimals: uint8
totalSupply: uint256
balanceOf: HashMap[address, uint256]
allowance: HashMap[address, HashMap[address, uint256]]
minter: address
@external
def __init__ (_name: String[64], _symbol: String[32], _decimals: uint8, _minter: address):
    self.name = _name
    self.symbol = _symbol
    self.minter = _minter
    self.decimal = _decimal
    self.total = 0 #at deployment , no one added liquidity , so no lp token should exist
@external
def mint(to: address, amount: uint256):
    assert msg.sender == self.minter , "not minter"
    self.totalSupply += amount
    self.balanceOf[to] += amount
@external
def burn (to: address, amount: uint256):
    assert msg.sender == self.minter , "not minter"
    self.balanceOf[to] -= amount
    self.totalSupply -= amount
    
@external
def transfer(to: address, amount: uint256) -> bool:
    assert self.balanceOf[msg.sender] >= amount , "insuff bal."
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[to] += amount
    return True

@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    return True 
@external
def transferFrom(owner: address, to: address, amount: uint256) -> bool:
    assert self.allowance[owner][msg.sender] >= amount , "spender not approved for enough."
    assert self.balanceOf[owner] >= amount , "insuff balance"
    self.allowance[ownner][msg.sender] -= amount
    self.balanceOf[owner] -= amount
    self.balanceOf[to] += amount
    return True

    
    
    
    
    
