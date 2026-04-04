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
def transfer(to: address, amount: uint256):
    assert self.balanceOf[msg.sender] >= amount
    self.msg.sender -= amount
    self.balanceOf[to] += amount
    
    
    
    
    
    
