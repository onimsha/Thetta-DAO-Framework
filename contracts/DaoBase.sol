pragma solidity ^0.4.22;

import "./IDaoBase.sol";
import "./DaoStorage.sol";
import "./DaoBaseLib.sol";


/**
 * @title DaoBase 
 * @dev Main Thetta DAO Framework contract. 
 * Usage scenarios:
 * 1) Preferred: become its client (derive your contract from DaoClient contract!)
 * 2) Optional: derive a contract directly from DaoBase  
 * 
 */
contract DaoBase is IDaoBase, Ownable {
	event DaoBaseUpgradeDaoContract(address _new);
	event DaoBaseAddGroupMember(string _groupName, address _a);
	event DaoBaseRemoveGroupMember(string _groupName, address _a);
	event DaoBaseAllowActionByShareholder(bytes32 _what, address _tokenAddress);
	event DaoBaseAllowActionByVoting(bytes32 _what, address _tokenAddress);
	event DaoBaseAllowActionByAddress(bytes32 _what, address _a);
	event DaoBaseAllowActionByAnyMemberOfGroup(bytes32 _what, string _groupName);
	event DaoBaseAddNewProposal(address _proposal);
	event DaoBaseIssueTokens(address _tokenAddress, address _to, uint _amount);
	event DaoBaseBurnTokens(address _tokenAddress, address _who, uint _amount);

	DaoStorage daoStorage;

	modifier isCanDo(bytes32 _permissionName){
		require(DaoBaseLib.isCanDoAction(daoStorage, msg.sender, _permissionName)); 
		_; 
	}

	modifier isCanDoOrByOwner(bytes32 _what) {
		require(msg.sender==owner || DaoBaseLib.isCanDoAction(daoStorage, msg.sender, _what));
		_;
	}

	bytes32 public constant ISSUE_TOKENS = 0xe003bf3bc29ae37598e0a6b52d6c5d94b0a53e4e52ae40c01a29cdd0e7816b71;
	bytes32 public constant MANAGE_GROUPS = 0x060990aad7751fab616bf14cf6b68ac4c5cdc555f8f06bc9f15ba1b156e81b0b;
	bytes32 public constant ADD_NEW_PROPOSAL = 0x55c7fa9eebcea37770fd33ec28acf7eacb6ea53052a9e9bc0a98169768578c5f;
	bytes32 public constant BURN_TOKENS = 0x324cd2c359ecbc6ad92db8d027aab5d643f27c3055619a49702576797bb41fe5;
	bytes32 public constant UPGRADE_DAO_CONTRACT = 0x3794eb44dffe1fc69d141df1b355cf30d543d8006634dd7a125d0e5f500b7fb1;
	bytes32 public constant REMOVE_GROUP_MEMBER = 0x3a5165e670fb3632ad283cd3622bfca48f4c8202b504a023dafe70df30567075;
	bytes32 public constant WITHDRAW_DONATIONS = 0xfc685f51f68cb86aa29db19c2a8f4e85183375ba55b5e56fb2e89adc5f5e4285;
	bytes32 public constant ALLOW_ACTION_BY_SHAREHOLDER = 0xbeaac974e61895532ee7d8efc953d378116d446667765b57f62c791c37b03c8d;
	bytes32 public constant ALLOW_ACTION_BY_VOTING = 0x2e0b85549a7529dfca5fb20621fe76f393d05d7fc99be4dd3d996c8e1925ba0b;
	bytes32 public constant ALLOW_ACTION_BY_ADDRESS = 0x087dfe531c937a5cbe06c1240d8f791b240719b90fd2a4e453a201ce0f00c176;
	bytes32 public constant ALLOW_ACTION_BY_ANY_MEMBER_OF_GROUP = 0xa7889b6adda0a2270859e5c6327f82b987d24f5729de85a5746ce28eed9e0d07;

	constructor(DaoStorage _daoStorage) public {
		daoStorage = _daoStorage;
	}

	/**
	* @param _s String which will be converted to hash
	* @return hash of provided string 
	* @dev Hash string
	*/
	function stringHash(string _s) public pure returns(bytes32) {
		return keccak256(_s);
	}

	/**
	* @return observers amount in storage
	*/
	function getObserversCount() public view returns(uint) {
		return daoStorage.getObserversCount();
	}

	/**
	* @param _index observer index in storage
	* @return address of the observer with provided index
	*/
	function getObserverAtIndex(uint _index) public view returns(address) {
		return daoStorage.getObserverAtIndex(_index);
	}	

	/**
	* @param _permissionName permission name in hash
	* @param _a address which will be checked for permissions
	* @return true if _a address have _permissionName permissions
	*/
	function isCanDoByGroupMember(bytes32 _permissionName, address _a) public view returns(bool) {
		return daoStorage.isAllowedActionByMembership(_permissionName, _a);
	}

	/**
	* @param _observer observer address
	* @dev add observer to storage
	*/
	function addObserver(IDaoObserver _observer) public {
		daoStorage.addObserver(_observer);
	}

	/**
	* @notice This function should be called only by account with UPGRADE_DAO_CONTRACT permissions
	* @param _new new DaoBase instance (address)
	* @dev this function upgrades DAO instance
	*/
	function upgradeDaoContract(IDaoBase _new) public isCanDo(UPGRADE_DAO_CONTRACT) {
		emit DaoBaseUpgradeDaoContract(_new); // call observers.onUpgrade() for all observers		
		for(uint i=0; i<daoStorage.getObserversCount(); ++i) {
			IDaoObserver(daoStorage.getObserverAtIndex(i)).onUpgrade(_new);
		}	
		
		daoStorage.transferOwnership(_new);

		for(i=0; i<daoStorage.getTokensCount(); ++i) { // transfer ownership of all tokens (this -> _new)
			daoStorage.getTokenAtIndex(i).transferOwnership(_new);
		} 
	}

	/**
	* @param _groupName name of the group in storage
    * @return amount of the members of the group with name _groupName
	*/
	function getMembersCount(string _groupName) public view returns(uint) {
		return daoStorage.getMembersCount(stringHash(_groupName));
	}

	/**
	* @notice This function should be called only by account with MANAGE_GROUPS permissions
	* @param _groupName name of the group in storage
	* @param _a address which will be added to the group with name _groupName
	* @dev this function add address _a to group na me with name _groupName into storage
	*/
	function addGroupMember(string _groupName, address _a) public isCanDoOrByOwner(MANAGE_GROUPS) {
		emit DaoBaseAddGroupMember(_groupName, _a);	
		require(bytes(_groupName).length>0);	
		daoStorage.addGroupMember(stringHash(_groupName), _a);
	}

	/**
	* @param _groupName name of the group in storage
    * @return array of addresses which in group name with name _groupName
	*/
	function getGroupMembers(string _groupName) public view returns(address[]) {
		return daoStorage.getGroupMembers(stringHash(_groupName));
	}

	/**
	* @notice This function should be called only by account with MANAGE_GROUPS permissions
	* @param _groupName name of the group in storage
	* @param _a address which will be removed from the group with name _groupName
	* @dev this function remove address _a from group name with name _groupName in storage
	*/
	function removeGroupMember(string _groupName, address _a) public isCanDoOrByOwner(MANAGE_GROUPS) {
		emit DaoBaseRemoveGroupMember(_groupName, _a);
		daoStorage.removeGroupMember(stringHash(_groupName), _a);
	}

	/**
	* @param _groupName name of the group in storage
	* @param _a address which will be checked on presence in group with name _groupName
	* @return true if address _a is in group with name _groupName
	*/
	function isGroupMember(string _groupName, address _a) public view returns(bool) {
		return daoStorage.isGroupMember(stringHash(_groupName), _a);
	}

	/**
	* @param _groupName name of the group in storage
	* @param _index address which will be added to the group with name _groupName
	* @return true if address corresponded to _index is group member of group with name _groupName
	*/
	function getMemberByIndex(string _groupName, uint _index) public view returns (address) {
		return daoStorage.getGroupsMemberAtIndex(stringHash(_groupName), _index);
	}

	/**
	* @notice This function should be called only by account with MANAGE_GROUPS permissions
	* @param _permissionName permission name in hash
	* @param _tokenAddress address of the token
	* @dev this function allows action with name _permissionName for _tokenAddress
	*/
	function allowActionByShareholder(bytes32 _permissionName, address _tokenAddress) public isCanDoOrByOwner(MANAGE_GROUPS) {
		emit DaoBaseAllowActionByShareholder(_permissionName, _tokenAddress);
		daoStorage.allowActionByShareholder(_permissionName, _tokenAddress);
	}

	/**
	* @notice This function should be called only by account with MANAGE_GROUPS permissions
	* @param _permissionName permission name in hash
	* @param _tokenAddress address of the token
	* @dev this function allows action with name _permissionName for _tokenAddress
	*/
	function allowActionByVoting(bytes32 _permissionName, address _tokenAddress) public isCanDoOrByOwner(MANAGE_GROUPS) {
		emit DaoBaseAllowActionByVoting(_permissionName, _tokenAddress);
		daoStorage.allowActionByVoting(_permissionName,_tokenAddress);
	}

	/**
	* @notice This function should be called only by account with MANAGE_GROUPS permissions
	* @param _permissionName permission name in hash
	* @param _a address
	* @dev this function allows action with name _permissionName for _tokenAddress
	*/
	function allowActionByAddress(bytes32 _permissionName, address _a) public isCanDoOrByOwner(MANAGE_GROUPS) {
		emit DaoBaseAllowActionByAddress(_permissionName, _a);
		daoStorage.allowActionByAddress(_permissionName,_a);
	}

	/**
	* @notice This function should be called only by account with MANAGE_GROUPS permissions
	* @param _permissionName permission name in hash
	* @param _groupName name of the group in storage
	* @dev this function allows action with name _permissionName for _tokenAddress
	*/
	function allowActionByAnyMemberOfGroup(bytes32 _permissionName, string _groupName) public isCanDoOrByOwner(MANAGE_GROUPS) {
		emit DaoBaseAllowActionByAnyMemberOfGroup(_permissionName, _groupName);
		daoStorage.allowActionByAnyMemberOfGroup(_permissionName, stringHash(_groupName));
	}

	/**
	 * @dev Function that will check if action is DIRECTLY callable by msg.sender (account or another contract)
	 * How permissions works now:
	 * 1. if caller is in the whitelist -> allow
	 * 2. if caller is in the group and this action can be done by group members -> allow
	 * 3. if caller is shareholder and this action can be done by a shareholder -> allow
	 * 4. if this action requires voting 
	 *    a. caller is in the majority -> allow
	 *    b. caller is voting and it is succeeded -> allow
	 * 4. deny
	*/
	function isCanDoAction(address _a, bytes32 _permissionNameHash) public view returns(bool) {
		return DaoBaseLib.isCanDoAction(daoStorage, _a, _permissionNameHash);
	}

	// Proposals:
	/**
	* @notice This function should be called only by account with ADD_NEW_PROPOSAL permissions
	* @param _proposal address of proposal
	* @dev this function adds proposal to storage
	*/
	function addNewProposal(IProposal _proposal) public isCanDo(ADD_NEW_PROPOSAL) { 
		emit DaoBaseAddNewProposal(_proposal); 
		daoStorage.addProposal(_proposal);
	}

	/**
	* @param _i index of the proposal in storage
	* @return proposal address
	*/
	function getProposalAtIndex(uint _i) public view returns(IProposal) {
		return daoStorage.getProposalAtIndex(_i);
	}

	/**
	* @return proposals amount in storage
	*/
	function getProposalsCount() public view returns(uint) {
		return daoStorage.getProposalsCount();
	}

	// Tokens:
	/**
	* @notice This function should be called only by account with ISSUE_TOKENS permissions
	* @param _tokenAddress address of token
	* @param _to address who gets issued tokens
	* @param _amount amount of tokens which will be issued
	* @dev this function issue tokens for address _to
	*/
	function issueTokens(address _tokenAddress, address _to, uint _amount) public isCanDo(ISSUE_TOKENS) {
		emit DaoBaseIssueTokens(_tokenAddress, _to, _amount);
		DaoBaseLib.issueTokens(
			daoStorage,
			_tokenAddress,
			_to,
			_amount
		);
	}

	/**
	* @notice This function should be called only by account with BURN_TOKENS permissions
	* @param _tokenAddress address of token
	* @param _who address whose tokens will be burned
	* @param _amount amount of tokens which will be burned
	* @dev this function burn tokens for address _who
	*/
	function burnTokens(address _tokenAddress, address _who, uint _amount) public isCanDo(BURN_TOKENS) {
		emit DaoBaseBurnTokens(_tokenAddress, _who, _amount);
		DaoBaseLib.burnTokens(
			daoStorage,
			_tokenAddress, 
			_who, 
			_amount
		);	
	}
}
