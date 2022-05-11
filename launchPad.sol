// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is IERC20Metadata{
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    uint8 private decimal;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //_beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable{
    address internal _owner;
    address internal _newOwner;
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    constructor () {
        _owner = msg.sender;
        emit OwnerSet( address(0), _owner );
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwner() public virtual onlyOwner() {
        emit OwnerSet( _owner, address(0) );
        _owner = address(0);
    }

    function ownerSet( address newOwner_ ) public onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnerSet( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
}

contract LaunchPad is Ownable,ERC20{
    IERC20Metadata _myToken;
    IERC20Metadata _customToken;
    bool public _finished = false;
    bool public _successed = false;

    address[] public myAddress;

    struct LaunchPadInfo {
        address  myToken;
        address  customToken;
        uint256  preSale;
        uint256  startTime;
        uint256  endTime;
        uint256  softTop;
        uint256  hardTop;
        uint256  min;
        uint256  max;
        uint256  ratio;
    }

    LaunchPadInfo public _launchPadInfo;

    mapping(address => uint256) public _balance;

    event setLaunchPadInfoEvent(LaunchPadInfo info);

    modifier OnlyAddressable(address addr){
        require(addr != address(0), "address cannot be address(0)");
        _;
    }
    constructor(){
        // _launchPadInfo.myToken = 0x7b96aF9Bd211cBf6BA5b0dd53aa61Dc5806b6AcE;
        // _myToken = IERC20Metadata(_launchPadInfo.myToken);
        // //_launchPadInfo.customToken = ;
        // _launchPadInfo.preSale =100;
        // _launchPadInfo.startTime =0;
        // _launchPadInfo.endTime = 999999999999;
        // _launchPadInfo.softTop = 50;
        // _launchPadInfo.hardTop = 100;
        // _launchPadInfo.min = 1;
        // _launchPadInfo.max = 10;
        // _launchPadInfo.ratio = 20;
    }

    function virtualSwap() external payable {
        require(msg.sender != address(0),"msg.sender address cannot be address(0)");
        require(!_finished , "IDO has already over.");
        require(msg.value >= _launchPadInfo.min &&
                _balance[msg.sender] + msg.value <= _launchPadInfo.max,
                "quantity out of range.");
        require(msg.value <= (_launchPadInfo.hardTop - getAmount()),
                "msg.value cannot be more than last remaining quantity");
        require(block.timestamp < _launchPadInfo.startTime, "activity not started");
        if(block.timestamp > _launchPadInfo.endTime){
            _finished = true;
        } 
        pushDataToSaveRecord(msg.sender,msg.value);
        pushDataToAddressArrary(msg.sender);
        _customToken.approve(msg.sender,_balance[msg.sender]);
        _myToken.approve(msg.sender,_balance[msg.sender] * _launchPadInfo.ratio);

        if((_launchPadInfo.hardTop - getAmount() < _launchPadInfo.min) &&
            getAmount() > _launchPadInfo.softTop && 
            getAmount() <= _launchPadInfo.hardTop){
            _finished = true;
            _successed = true;
        }
    }

    function getBackToken(address recipient,uint256 amount_) external payable OnlyAddressable(recipient) {
        require(msg.sender != address(0),"msg.sender address cannot be address(0)");
        require(_finished,"the launchpad is not over");

        uint256 oldbanlance = _balance[msg.sender];

        require(oldbanlance >= 0,"Insufficient account balance");
        require(oldbanlance >= amount_,"Insufficient withdrawal amount");
        if(_successed){         
            require(_myToken.allowance(_owner,msg.sender) >= amount_ * _launchPadInfo.ratio,
                "_myToken allowance too low"
            );
            require(_launchPadInfo.preSale > amount_ * _launchPadInfo.ratio,
                "myToken is not enough"
            );
            _myToken.transferFrom(_owner,recipient,amount_ * _launchPadInfo.ratio);
            _balance[msg.sender] = oldbanlance-amount_;

        }else {
            require(_customToken.allowance(_owner,msg.sender) >= amount_,
               "_customToken allowance too low"
            );
            _customToken.transferFrom(_owner,recipient,amount_);
            _balance[msg.sender] = oldbanlance-amount_;
       }
    }

    function setLaunchPadInfo(LaunchPadInfo memory info) external onlyOwner returns(LaunchPadInfo memory ){
        require(info.myToken != address(0),"myToken address cannot be address(0)");
        _launchPadInfo.myToken =info.myToken;
        _myToken = IERC20Metadata(_launchPadInfo.myToken);

        require(info.customToken != address(0),"customToken address cannot be address(0)");
        _launchPadInfo.customToken =info.customToken; 
        _customToken = IERC20Metadata(_launchPadInfo.customToken);

        require(
            info.startTime >= block.timestamp && info.endTime >info.startTime,
            "launchpad time error"
        );
        _launchPadInfo.startTime = info.startTime;
        _launchPadInfo.endTime = info.endTime;   

        require(info.softTop > 0 ,"launchpad softroof cannot be less than zero");
        require(info.hardTop >= info.softTop ,"launchpad hardtop cannot less than softtop");
        _launchPadInfo.softTop = info.softTop;
        _launchPadInfo.hardTop = info.hardTop;   

        require(info.min >= 0 ,"launchpad min cannot be less than zero");
        require(info.max >= info.min ,"launchpad max cannot less than min");
        _launchPadInfo.min = info.min;
        _launchPadInfo.max = info.max; 

        require(info.ratio >= 0 , "ratio cannot be less than zero");
        _launchPadInfo.ratio = info.ratio;

        require(_launchPadInfo.preSale >= _launchPadInfo.hardTop * _launchPadInfo.ratio,
            "Insufficient pre-sale quantity"
        );

        emit setLaunchPadInfoEvent(_launchPadInfo);
        return _launchPadInfo;
    }

    function withdrawCurrencyToAccount() external onlyOwner returns(uint256){
        require(_finished,"the launchpad is not over");
        if(_successed){
            _customToken.transfer(_owner,getAmount());
            return getAmount();
        }
        return 0;
    }

    function checkLaunchSuccessed() external view returns(bool){
        if(getAmount() >= _launchPadInfo.softTop && getAmount() <= _launchPadInfo.hardTop){
            return true;
        }
        return false;
    }

    function getLaunchPadInfo() public view returns(LaunchPadInfo memory ){
        return _launchPadInfo;
    }
    
    function getTotalSupply() public view returns(uint256){
        return _myToken.balanceOf(_owner);
    }

    function getTokenName() public view returns(string memory){
        return _myToken.name();
    }

    function getTokenSymbol() public view returns(string memory){
        return  _myToken.symbol();
    }

    function getTokenDecimals() public view returns(uint8){
        return _myToken.decimals();
    }

    function getAddressLength() public view returns(uint256){
        return myAddress.length;
    }

    function getAmount() public view returns(uint256 amount){
        for(uint i=0 ; i<myAddress.length ; i++){
            amount += _balance[myAddress[i]];
        }
    }

    function setLaunchPadFinished( bool finished_) public onlyOwner  {
        _finished = finished_;
    }

    function getLaunchPadFinished() public view returns(bool){
        return _finished;
    }

    function setLaunchPadSuccessed(bool successed_) public onlyOwner {
        _successed = successed_;
    }

    function getLaunchPadSuccessed() public view returns(bool){
        return _successed;
    }

    function getAddressArrary() public view returns(address[] memory){
        return myAddress;
    }

    function checkAddressArrary(address addr) private view OnlyAddressable(addr) returns(bool){
        if(myAddress.length>0){
            for(uint i=0;i<myAddress.length;i++){
                if(myAddress[i] == addr){
                    return false;
                }
            }
        }
        return true;
    }
    
    function pushDataToAddressArrary(address addr) private OnlyAddressable(addr) returns(bool){
        if(checkAddressArrary(addr)){
            myAddress.push(addr);
            return true;
        }
        return false;
    }

    function pushDataToSaveRecord(address from_,uint256 value) private OnlyAddressable(from_) returns (bool){
        require(value > 0,"value cannot be less than zero");
        _balance[from_] += value;
        return true;
    }

}