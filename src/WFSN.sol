// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "freemoon-frc759/FRC759.sol";
import "freemoon-frc759/libraries/SafeMath.sol";

import "./interfaces/IWFSN.sol";


contract WFSN is FRC759, IWFSN {
    using SafeMath for uint256;

    constructor() FRC759("Wrapped Fusion", "WFSN", 18, type(uint256).max) {}

    receive() external payable {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external override payable {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external override {
        _withdraw(msg.sender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override(FRC759, IWFSN) returns (bool) {
        uint256 _allowance = ISlice(fullTimeToken).allowance(from, msg.sender);

        if (to == address(0) || from == address(this)) {
            if (amount < _allowance) revert InsufficientAllowance();
            _withdraw(from, amount);
        } else {
            ISlice(fullTimeToken).transferByParent(from, to, amount);
        }
        
        ISlice(fullTimeToken).approveByParent(from, msg.sender, _allowance.sub(amount, "FRC759: too less allowance"));

        return true;
    }

    function transferFromData(address from, address to, uint256 amount, bytes calldata data) public override(FRC759, IWFSN) returns (bool) {
        uint256 _allowance = ISlice(fullTimeToken).allowance(from, msg.sender);

        if (to == address(0) || to == address(this)) {
            if (amount > _allowance) revert InsufficientAllowance();
            _withdraw(from, amount);
        } else {
            ISlice(fullTimeToken).transferByParent(from, to, amount);
        }
        
        ISlice(fullTimeToken).approveByParent(from, msg.sender, _allowance.sub(amount, "FRC759: too less allowance"));

        emit DataDelivery(data);

        return true;
    }
    
    function transfer(address to, uint256 amount) public override(FRC759, IWFSN) returns (bool) {
        if (to == address(0) || to == address(this)) {
            _withdraw(msg.sender, amount);
        } else {
            ISlice(fullTimeToken).transferByParent(msg.sender, to, amount);
        }
 
        return true;
    }

    function transferData(address to, uint256 amount, bytes calldata data) public override(FRC759, IWFSN) returns (bool) {
        if (to == address(0) || to == address(this)) {
            _withdraw(msg.sender, amount);
        } else {
            ISlice(fullTimeToken).transferByParent(msg.sender, to, amount);
        }

        emit DataDelivery(data);

        return true;
    }

    function burn(address account, uint256 amount) public {
        if (msg.sender != account) revert Forbidden();

        _withdraw(account, amount);
    }

    // **** PRIVATE ****
    function _withdraw(address account, uint256 amount) private {
        _burn(account, amount);
        _safeTransferETH(account, amount);

        emit Withdrawal(account, amount);
    }

    function _safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert TransferETHFailed();
    }
}