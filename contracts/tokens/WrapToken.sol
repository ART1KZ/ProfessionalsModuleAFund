// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import "contracts/ERC20Bundle.sol";

contract WrapToken is ERC20 {
    constructor() ERC20("RTKCoin", "RTK") {
        _mint(msg.sender, 20000000 * 10**decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function price() public pure returns (uint256) {
        return 1 ether;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns(bool) {
        _transfer(_from, _to, _amount);
        return true;
    }
}
