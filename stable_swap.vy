# usdt and usdc
token0: address
token1: address

# how many are in the pool
reserve0: uint256
reserve1: uint256

# amplification coefficient — controls how flat the curve is
# higher A = flatter = lower slippage
A: uint256

# address , so we can call mint and burn
lp_token: address

# fee charged on each swap in Vyper!
fee: uint256

@external
def __init__(_token0: address, _token1: address, _A: uint256, _fee: uint256, _lp_token: address):
    self.token0 = _token0
    self.token1 = _token1
    self.A = _A
    self.fee = _fee
    self.lp_token = _lp_token
interface ERC20:
    def transferFrom(owner: address, to: address, amount: uint256) -> bool: nonpayable
    def transfer(to: address, amount: uint256) -> bool: nonpayable
interface LPtoken:
    def mint(to: address, amount: uint256): nonpayable
    def burn(to: address, amount: uint256): nonpayable

