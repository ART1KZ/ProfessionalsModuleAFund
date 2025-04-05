// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import "../bundles/ERC20Bundle.sol";

contract WrapToken is ERC20 {
    address public owner;

    constructor(address _owner) ERC20("RTKCoin", "RTK") {
        owner = _owner;
        _mint(msg.sender, 20000000 * 10**decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function price() public pure returns (uint256) {
        return 1 ether;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns(bool) {
        _transfer(_from, _to, _amount);
        return true;
    }
}
