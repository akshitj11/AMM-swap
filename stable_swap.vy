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
    def transferFrom(owner: address, to: address, amount: uint256) -> bool: nonpayable #nonpayable becuase this function does not accept ETH it just moves erc 20 tokens not eth
    def transfer(to: address, amount: uint256) -> bool: nonpayable
interface LPtoken:
    def mint(to: address, amount: uint256): nonpayable
    def burn(to: address, amount: uint256): nonpayable

@internal
def _sqrt(x: uint256) -> uint256:
    if x == 0:
        return 0
    z: uint256 = (x + 1) / 2
    y: uint256 = x
    for _ in range(256): 
        if z >= y:
            return y
        y = z
        z = (x / z + z) / 2
    return y

@external
def add_liquidity(amount0: uint256, amount1: uint256) -> uint256: #return amount of lp token minted
   ERC20(self.token0).transferFrom(msg.sender, self, amount0)
   ERC20(self.token1).transferFrom(msg.sender, self, amount1) 
   #calculating lp token to mint
   lp_amount: uint256 = 0
   totol_supply: uint256 = LPToken(self.lp_token).totalSupply()
   #fetching current lp token supply from lp.vy
   #if 0 , pool is empty and it is the first deposit
   if total_supply == 0:
    #1st deposit =use gm as starting lp amount
    lp_amount = self._sqrt(amount0 * amount1)
    # 100usdc, 100usdt -> srt(100*100) = 100 lp tokens
   else:
    lp_amount = min(
        amount0 * total_supply / self.reserve0,
        amount1 * total_supply / self.reserve1
         assert lp_amount > 0, "insufficient liquidity minted"
    LPToken(self.lp_token).mint(msg.sender, lp_amount)
    self.reserve0 += amount0
    self.reserve1 += amount1
    return lp_amount
    )

    
