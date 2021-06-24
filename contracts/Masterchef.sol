// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './interfaces/IBEP20.sol';
import './interfaces/IMars.sol';
import './utils/SafeBEP20.sol';

// MasterChef is the master of Mars. He can make Mars and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Mars is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Masterchef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 depositedAt;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Marss to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Marss distribution occurs.
        uint256 accMarsPerShare;   // Accumulated Marss per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The Mars TOKEN!
    IMars public mars;
    // Dev address.
    address public devaddr;
    // Mars tokens created per block.
    uint256 public marsPerBlock;
    // Bonus muliplier for early mars makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Withdraw fee address
    address public treasuryAddress;

    address public climb;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // climb holder list
    address[] public climbHolders;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Mars mining starts.
    uint256 public startBlock;

    uint256 public WITHDRAWAL_FEE_DEDUCT_PERIOD = 3 days;
    uint256 public withdrawFee = 200;   // 2% for withdraw fee
    uint256 public deductedWithdrawFee = 50;    // .5% for deducted withdraw fee

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IMars _mars,
        address _devaddr,
        address _feeAddress,
        uint256 _marsPerBlock,
        uint256 _startBlock
    ) public {
        mars = _mars;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        treasuryAddress = msg.sender;
        marsPerBlock = _marsPerBlock;
        startBlock = _startBlock;
        climb = 0x2A1d286ed5edAD78BeFD6E0d8BEb38791e8cD69d;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accMarsPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's Mars allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Marss on frontend.
    function pendingMars(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMarsPerShare = pool.accMarsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 marsReward = multiplier.mul(marsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMarsPerShare = accMarsPerShare.add(marsReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMarsPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 marsReward = multiplier.mul(marsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        mars.mint(devaddr, marsReward.div(10));
        mars.mint(address(this), marsReward);
        pool.accMarsPerShare = pool.accMarsPerShare.add(marsReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Mars allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMarsPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeMarsTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                if (address(pool.lpToken) == climb) {
                    if (user.amount == 0) {
                        climbHolders.push(msg.sender);
                    }
                }
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMarsPerShare).div(1e12);
        user.depositedAt = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMarsPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeMarsTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint withdrawalFee = _withdrawalFee(_amount, user.depositedAt);
            if (withdrawalFee > 0) {
                pool.lpToken.safeTransfer(treasuryAddress, withdrawalFee);
            }
            _amount = _amount.sub(withdrawalFee);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            if (user.amount == 0) {
                uint userIndexInHolders = getIndexInClimbHolders(msg.sender);
                if (userIndexInHolders != 1e27) {
                    _removeUserFromClimbHolders(userIndexInHolders);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMarsPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe mars transfer function, just in case if rounding error causes pool to not have enough Marss.
    function safeMarsTransfer(address _to, uint256 _amount) internal {
        uint256 marsBal = mars.balanceOf(address(this));
        if (_amount > marsBal) {
            mars.transfer(_to, marsBal);
        } else {
            mars.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) public {
        require(msg.sender == treasuryAddress, 'setTreasuryAddress: FORBIDDEN');
        treasuryAddress = _treasuryAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _marsPerBlock) public onlyOwner {
        massUpdatePools();
        marsPerBlock = _marsPerBlock;
    }

    function setClimbAddress(address _climb) public onlyOwner {
        climb = _climb;
    }

    function setWithdrawFee(uint256 _fee) public onlyOwner {
        require(_fee < 10000, 'invalid fee');
        withdrawFee = _fee;
    }

    function setDeductedWithdrawFee(uint256 _fee) public onlyOwner {
        require(_fee < 10000, 'invalid fee');
        deductedWithdrawFee = _fee;
    }

    function getIndexInClimbHolders(address _user) public view returns (uint) {
        uint index = 1e27;
        for (uint i = 0; i < climbHolders.length; i++) {
            if (_user == climbHolders[i]) {
                index = i;
            }
        }
        return index;
    }

    function _removeUserFromClimbHolders(uint _index) internal {
        for (uint i = _index; i < climbHolders.length - 1; i++) {
            climbHolders[i] = climbHolders[i + 1];
        }
        climbHolders.pop();
    }

    function _withdrawalFee(uint amount, uint depositedAt) internal view returns (uint) {
        if (depositedAt.add(WITHDRAWAL_FEE_DEDUCT_PERIOD) > block.timestamp) {
            return amount.mul(withdrawFee).div(1000);
        }
        return amount.mul(deductedWithdrawFee).div(1000);
    }
}
