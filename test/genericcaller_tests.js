var MicrocompanyWithUnpackers = artifacts.require("./MicrocompanyWithUnpackers");
var StdMicrocompanyToken = artifacts.require("./StdMicrocompanyToken");
var MicrocompanyStorage = artifacts.require("./MicrocompanyStorage");

var AutoMicrocompanyActionCaller = artifacts.require("./AutoMicrocompanyActionCaller");

var Voting = artifacts.require("./Voting");
var IProposal = artifacts.require("./IProposal");

var CheckExceptions = require('./utils/checkexceptions');

global.contract('GenericCaller', (accounts) => {
	const creator = accounts[0];
	const employee1 = accounts[1];
	const employee2 = accounts[2];
	const outsider = accounts[3];

	global.beforeEach(async() => {

	});
	/*
	global.it('should not automatically create proposal because AAC has no rights',async() => {
		let token = await StdMicrocompanyToken.new("StdToken","STDT",18,{from: creator});
		await token.mint(creator, 1000);
		let store = await MicrocompanyStorage.new(token.address,{gas: 10000000, from: creator});

		let mcInstance = await MicrocompanyWithUnpackers.new(store.address,{gas: 10000000, from: creator});
		let aacInstance = await AutoMicrocompanyActionCaller.new(mcInstance.address, {from: creator});

		{
			// manually setup the Default organization 
			await store.addActionByEmployeesOnly("addNewProposal");

			// this is a list of actions that require voting
			await store.addActionByVoting("addNewEmployee", token.address);
			await store.addActionByVoting("issueTokens", token.address);

			// THIS IS REQUIRED because issueTokensAuto() will add new proposal (voting)
			// because of this AAC can't add new proposal!
			// 
			//await store.addActionByAddress("addNewProposal", aacInstance.address);

			// add creator as first employee	
			await store.addNewEmployee(creator);			
		}

		// do not forget to transfer ownership
		await token.transferOwnership(mcInstance.address);
		await store.transferOwnership(mcInstance.address);

		const proposalsCount1 = await mcInstance.getProposalsCount();
		global.assert.equal(proposalsCount1,0,'No proposals should be added');

		// add new employee1
		await mcInstance.addNewEmployee(employee1,{from: creator});
		const isEmployeeAdded = await mcInstance.isEmployee(employee1);
		global.assert.strictEqual(isEmployeeAdded,true,'employee1 should be added as the company`s employee');

		// new proposal should NOT be added 
		await CheckExceptions.checkContractThrows(aacInstance.issueTokensAuto.sendTransaction,
			[employee1,1000,{ from: employee1}],
			'Should not be able to issue tokens AND add new proposal');

		const proposalsCount2 = await mcInstance.getProposalsCount();
		global.assert.equal(proposalsCount2,0,'No new proposal should be added because'); 
	});

	global.it('should not automatically create proposal because issueTokens cant be called even with voting',async() => {
		let token = await StdMicrocompanyToken.new("StdToken","STDT",18,{from: creator});
		await token.mint(creator, 1000);
		let store = await MicrocompanyStorage.new(token.address,{gas: 10000000, from: creator});

		let mcInstance = await MicrocompanyWithUnpackers.new(store.address,{gas: 10000000, from: creator});
		let aacInstance = await AutoMicrocompanyActionCaller.new(mcInstance.address, {from: creator});

		{
			// manually setup the Default organization 
			await store.addActionByEmployeesOnly("addNewProposal");

			// this is a list of actions that require voting
			await store.addActionByVoting("addNewEmployee", token.address);

			// SEE this -> this permissions is commented! So even if AAC has rights to add proposal, 
			// the proposal will never be finished 
			// 
			//await store.addActionByVoting("issueTokens", token.address);

			// THIS IS REQUIRED because issueTokensAuto() will add new proposal (voting)
			await store.addActionByAddress("addNewProposal", aacInstance.address);

			// add creator as first employee	
			await store.addNewEmployee(creator);			
		}

		// do not forget to transfer ownership
		await token.transferOwnership(mcInstance.address);
		await store.transferOwnership(mcInstance.address);

		// even creator cant issue token!
		await CheckExceptions.checkContractThrows(mcInstance.issueTokens.sendTransaction,
			[employee1, 1500 ,{ from: creator}],
			'Even creator cant issue tokens');

		// 
		const proposalsCount1 = await mcInstance.getProposalsCount();
		global.assert.equal(proposalsCount1,0,'No proposals should be added');

		// add new employee1
		await mcInstance.addNewEmployee(employee1,{from: creator});
		const isEmployeeAdded = await mcInstance.isEmployee(employee1);
		global.assert.strictEqual(isEmployeeAdded,true,'employee1 should be added as the company`s employee');

		// employee1 is NOT in the majority
		const isCanDo1 = await mcInstance.isCanDoAction(employee1,"issueTokens");
		global.assert.strictEqual(isCanDo1,false,'employee1 is NOT in the majority, so can issue token only with voting');
		const isCanDo2 = await mcInstance.isCanDoAction(employee1,"addNewProposal");
		global.assert.strictEqual(isCanDo2,true,'employee1 can add new vote');

		// new proposal should be added 
		await aacInstance.issueTokensAuto(employee1,1000,{from: employee1});
		const proposalsCount2 = await mcInstance.getProposalsCount();
		global.assert.equal(proposalsCount2,1,'New proposal should be added'); 

		// check the voting data
		const pa = await mcInstance.getProposalAtIndex(0);
		const proposal = await IProposal.at(pa);
		const votingAddress = await proposal.getVoting();
		const voting = await Voting.at(votingAddress);
		global.assert.strictEqual(await voting.isFinished(),false,'Voting is still not finished');
		global.assert.strictEqual(await voting.isYes(),false,'Voting is still not finished');

		// should not vote! because ACTION will throw 
		// i.e. 'issueTokens' action is disabled!
		//
		await voting.vote(true,0,{from:employee1});

		// TODO: uncomment! this condition should be met 
		
		// await CheckExceptions.checkContractThrows(voting.vote.sendTransaction,
		// 	[true,{ from: employee1}],
		// 	'issueTokens is not allowed!');
		

		const r2 = await voting.getFinalResults();
		global.assert.equal(r2[0],2,'yes');			// 1 already voted (who started the voting)
		global.assert.equal(r2[1],0,'no');
		global.assert.equal(r2[2],2,'total');

		// get voting results again
		global.assert.strictEqual(await voting.isFinished(),true,'Voting is still not finished');
		global.assert.strictEqual(await voting.isYes(),true,'Voting is still not finished');
		
		const balance2 = await token.balanceOf(employee1);
		global.assert.notEqual(balance2.toNumber(),1000,'employee1 balance should NOT be updated');
	});

	global.it('should automatically create proposal and voting to issue more tokens',async() => {
		let token = await StdMicrocompanyToken.new("StdToken","STDT",18,{from: creator});
		await token.mint(creator, 1000);
		let store = await MicrocompanyStorage.new(token.address,{gas: 10000000, from: creator});

		let mcInstance = await MicrocompanyWithUnpackers.new(store.address,{gas: 10000000, from: creator});
		let aacInstance = await AutoMicrocompanyActionCaller.new(mcInstance.address, {from: creator});

		{
			// manually setup the Default organization 
			await store.addActionByEmployeesOnly("addNewProposal");

			// this is a list of actions that require voting
			await store.addActionByVoting("addNewEmployee", token.address);
			await store.addActionByVoting("issueTokens", token.address);

			// THIS IS REQUIRED because issueTokensAuto() will add new proposal (voting)
			await store.addActionByAddress("addNewProposal", aacInstance.address);

			// add creator as first employee	
			await store.addNewEmployee(creator);			
		}

		// do not forget to transfer ownership
		await token.transferOwnership(mcInstance.address);
		await store.transferOwnership(mcInstance.address);

		const proposalsCount1 = await mcInstance.getProposalsCount();
		global.assert.equal(proposalsCount1,0,'No proposals should be added');

		// add new employee1
		await mcInstance.addNewEmployee(employee1,{from: creator});
		const isEmployeeAdded = await mcInstance.isEmployee(employee1);
		global.assert.strictEqual(isEmployeeAdded,true,'employee1 should be added as the company`s employee');

		// employee1 is NOT in the majority
		const isCanDo1 = await mcInstance.isCanDoAction(employee1,"issueTokens");
		global.assert.strictEqual(isCanDo1,false,'employee1 is NOT in the majority, so can issue token only with voting');
		const isCanDo2 = await mcInstance.isCanDoAction(employee1,"addNewProposal");
		global.assert.strictEqual(isCanDo2,true,'employee1 can add new vote');

		// new proposal should be added 
		await aacInstance.issueTokensAuto(employee1,1000,{from: employee1});
		const proposalsCount2 = await mcInstance.getProposalsCount();
		global.assert.equal(proposalsCount2,1,'New proposal should be added'); 

		// check the voting data
		const pa = await mcInstance.getProposalAtIndex(0);
		const proposal = await IProposal.at(pa);
		const votingAddress = await proposal.getVoting();
		const voting = await Voting.at(votingAddress);
		global.assert.strictEqual(await voting.isFinished(),false,'Voting is still not finished');
		global.assert.strictEqual(await voting.isYes(),false,'Voting is still not finished');

		const r = await voting.getFinalResults();
		global.assert.equal(r[0],1,'yes');			// 1 already voted (who started the voting)
		global.assert.equal(r[1],0,'no');
		global.assert.equal(r[2],1,'total');

		const balance1 = await token.balanceOf(employee1);
		global.assert.strictEqual(balance1.toNumber(),0,'initial employee1 balance');

		// vote again
		// should execute the action (issue tokens)!
		await voting.vote(true,0,{from:employee1});
		const r2 = await voting.getFinalResults();
		global.assert.equal(r2[0],2,'yes');			// 1 already voted (who started the voting)
		global.assert.equal(r2[1],0,'no');
		global.assert.equal(r2[2],2,'total');

		// get voting results again
		global.assert.strictEqual(await voting.isFinished(),true,'Voting is finished now');
		global.assert.strictEqual(await voting.isYes(),true,'Voting result is yes!');

		const balance2 = await token.balanceOf(employee1);
		global.assert.strictEqual(balance2.toNumber(),1000,'employee1 balance should be updated');

		// should not call vote again 
		await CheckExceptions.checkContractThrows(voting.vote.sendTransaction,
			[true,{ from: creator}],
			'Should not call action again');
	});*/

	global.it('should be able to upgrade ',async() => {
		let token = await StdMicrocompanyToken.new("StdToken","STDT",18,{from: creator});
		await token.mint(creator, 1000);
		let store = await MicrocompanyStorage.new(token.address,{gas: 10000000, from: creator});

		let mcInstance = await MicrocompanyWithUnpackers.new(store.address,{gas: 10000000, from: creator});
		let aacInstance = await AutoMicrocompanyActionCaller.new(mcInstance.address, {from: creator});

		{
			// await store.addActionByEmployeesOnly("issueTokens");
			await store.addActionByEmployeesOnly("addNewEmployee");
			await store.addActionByVoting("upgradeMicrocompany", token.address);
			// await store.addActionByEmployeesOnly("upgradeMicrocompany");
			// add creator as first employee	
			await store.addNewEmployee(creator);			
		}

		// do not forget to transfer ownership
		await token.transferOwnership(mcInstance.address);
		await store.transferOwnership(mcInstance.address);

		const proposalsCount1 = await mcInstance.getProposalsCount();
		global.assert.equal(proposalsCount1,0,'No proposals should be added');

		let mcInstanceNew = await MicrocompanyWithUnpackers.new(store.address,{gas: 10000000, from: creator});


		let upgradeMicrocompany = await mcInstance.isCanDoAction(creator, "upgradeMicrocompany")
		console.log('upgradeMicrocompany:', upgradeMicrocompany)
		// await aacInstance.upgradeMicrocompanyContractAuto(mcInstanceNew.address,{from: creator});

		let aacInstanceNew = await AutoMicrocompanyActionCaller.new(mcInstanceNew.address, {from: creator});
		// const proposalsCount2 = await mcInstance.getProposalsCount();
		// global.assert.equal(proposalsCount2,1,'New proposal should be added'); 


		// const pa = await mcInstance.getProposalAtIndex(0);
		// const proposal = await IProposal.at(pa);
		// const votingAddress = await proposal.getVoting();
		// const voting = await Voting.at(votingAddress);
		// global.assert.strictEqual(await voting.isFinished(),false,'Voting is still not finished');
		// global.assert.strictEqual(await voting.isYes(),false,'Voting is still not finished');

		// await voting.vote(true,0,{from:employee1});

		// const r2 = await voting.getFinalResults();
		// global.assert.equal(r2[0],2,'yes');			// 1 already voted (who started the voting)
		// global.assert.equal(r2[1],0,'no');
		// global.assert.equal(r2[2],2,'total');

		// // get voting results again
		// global.assert.strictEqual(await voting.isFinished(),true,'Voting is still not finished');
		// global.assert.strictEqual(await voting.isYes(),true,'Voting is still not finished');
		

		// await mcInstance.issueTokens(employee2,1000,{from: creator});
		// await mcInstance.addNewEmployee(employee2);
		
		

		// await mcInstance.upgradeMicrocompanyContract(mcInstanceNew.address, {gas: 10000000, from: creator})
		
		// await mcInstanceNew.issueTokens(employee1,1000,{from: creator});
		// await mcInstanceNew.addNewEmployee(employee1);

		// await CheckExceptions.checkContractThrows(mcInstance.addNewEmployee,
		// 	[employee2, { from: creator}],
		// 	'Should not add new employee');

		// await CheckExceptions.checkContractThrows(mcInstance.issueTokens,
		// 	[employee2, { from: creator}],
		// 	'Should not issue tokens');
		
	});

});
