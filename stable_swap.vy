# @version ^0.3.10

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
interface LPToken:
    def mint(to: address, amount: uint256): nonpayable
    def burn(to: address, amount: uint256): nonpayable
    def totalSupply() -> uint256: view

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
   total_supply: uint256 = LPToken(self.lp_token).totalSupply()
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
    )
   assert lp_amount > 0, "insufficient liquidity minted"
   LPToken(self.lp_token).mint(msg.sender, lp_amount)
   self.reserve0 += amount0
   self.reserve1 += amount1
   return lp_amount
    

@external
def remove_liquidity(lp_amount: uint256) -> (uint256, uint256):
    
    total_supply: uint256 = LPToken(self.lp_token).totalSupply()
    amount0: uint256 = lp_amount * self.reserve0 / total_supply
    amount1: uint256 = lp_amount * self.reserve1 / total_supply
    
    assert amount0 > 0 and amount1 > 0, "insufficient liquidity burned"
    LPToken(self.lp_token).burn(msg.sender, lp_amount)
    ERC20(self.token0).transfer(msg.sender, amount0)
    ERC20(self.token1).transfer(msg.sender, amount1)
    self.reserve0 -= amount0
    self.reserve1 -= amount1
    return amount0, amount1

@internal
def _get_D(x: uint256, y: uint256) -> uint256:
    S: uint256 = x + y
    if S == 0:
        return 0
   
    D: uint256 = S
    Ann: uint256 = 4 * self.A
    for _ in range(255):
        D_prev: uint256 = D
        D3: uint256 = D * D * D
        D = (Ann * S + 2 * D3 / (x * y)) * D / ((Ann - 1) * D + 3 * D3 / (x * y))

        if D > D_prev:
            if D - D_prev <= 1:
                return D
        else:
            if D_prev - D <= 1:
                return D

    return D
       
@internal
def _get_y(x_new: uint256, D: uint256) -> uint256:

    Ann: uint256 = 4 * self.A
    b: uint256 = x_new + D / Ann
    c: uint256 = D * D * D / (4 * x_new * Ann)
    y: uint256 = D
    for _ in range(255):
        y_prev: uint256 = y
        y = (y * y + c) / (2 * y + b - D)
        if y > y_prev:
            if y - y_prev <= 1:
                return y
        else:
            if y_prev - y <= 1:
                return y

    return y

@external
def swap(token_in: address, amount_in: uint256) -> uint256:
    is_token0: bool = token_in == self.token0
    assert is_token0 or token_in == self.token1, "invalid token"
    ERC20(token_in).transferFrom(msg.sender, self, amount_in)
    D: uint256 = self._get_D(self.reserve0, self.reserve1)
    x_new: uint256 = 0
    y_old: uint256 = 0
    y_new: uint256 = 0

    if is_token0:
        x_new = self.reserve0 + amount_in
        y_old = self.reserve1
        y_new = self._get_y(x_new, D)
    else:
        x_new = self.reserve1 + amount_in
        y_old = self.reserve0
        y_new = self._get_y(x_new, D)
    amount_out: uint256 = y_old - y_new
    fee_amount: uint256 = amount_out * self.fee / 10000
    amount_out = amount_out - fee_amount
    assert amount_out > 0, "insufficient output amount"
    if is_token0:
        ERC20(self.token1).transfer(msg.sender, amount_out)
    else:
        ERC20(self.token0).transfer(msg.sender, amount_out)

    if is_token0:
        self.reserve0 += amount_in
        self.reserve1 = y_new + fee_amount
    else:
        self.reserve1 += amount_in
        self.reserve0 = y_new + fee_amount
    return amount_out