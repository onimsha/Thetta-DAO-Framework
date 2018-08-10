pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

import "../IMoneyflow.sol";
import "../ISplitter.sol";

/**
 * @title SplitterBase 
 * @dev Splitter has multiple outputs (allows to send money only to THESE addresses)
*/
contract SplitterBase is ISplitter, Ownable {
	using SafeMath for uint;
	bool opened = true;
	mapping (uint=>address) children;
	uint childrenCount = 0;

	string public name = "";

	event SplitterBase_ProcessFunds(address _sender, uint _value, uint _currentFlow);
	event SplitterBase_Open(address _sender);
	event SplitterBase_Close(address _sender);
	event SplitterBase_AddChild(address _newChild);

	constructor(string _name) public {
		name = _name;
	}

	// ISplitter:
	function open() public onlyOwner {
		emit SplitterBase_Open(msg.sender);
		opened = true;
	}

	function close() public onlyOwner {
		emit SplitterBase_Close(msg.sender);
		opened = false;
	}

	function isOpen() public view returns(bool) {
		return opened;
	}

	function getChildrenCount()public view returns(uint) {
		return childrenCount;
	}

	function getChild(uint _index)public view returns(address) {
		return children[_index];
	}

	function addChild(address _newChild) public onlyOwner {
		emit SplitterBase_AddChild(_newChild);
		children[childrenCount] = _newChild;
		childrenCount = childrenCount + 1;	
	}
}