// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../bundles/ERC20Bundle.sol";

contract SystemToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(uint256 _totalSupply, address acc1, address acc2, address acc3) ERC20("Professional", "PROFI") ERC20Permit("PROFI") {
        uint256 initBalanceForAccount = _totalSupply / 3;
        _mint(acc1, initBalanceForAccount * 10**decimals());
        _mint(acc2, initBalanceForAccount * 10**decimals());
        _mint(acc3, initBalanceForAccount * 10**decimals());
    }

    function decimals() public pure override returns(uint8) {
        return 12;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns(bool) {
        _transfer(_from, _to, _amount);
        return true;
    }

    function nonces(address owner)
        public
        view
        virtual
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}