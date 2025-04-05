// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GovernanceBundle.sol";
import {SystemToken} from "./tokens/SystemToken.sol";
import {WrapToken} from "./tokens/WrapToken.sol";

contract Fund is Governor, GovernorCountingSimple, GovernorVotes {
    SystemToken systemToken;
    WrapToken wrapToken;

    uint8 public systemTokensPerVote;
    enum ProposalType {
        A,
        B,
        C,
        D,
        E,
        F
    }

    enum QuorumMechanism {
        SimpleMajority,
        SuperMajority,
        Weighted
    }

    enum VotingStatus {
        Decided,
        Undecided,
        Deleted
    }

    struct UnvotedProposal {
        address proposedBy;
        ProposalType proposalType;
        address target;
        uint256 value;
        bytes functionCalldata;
        string description;
    }

    struct VotedProposal {
        uint256 id;
        address proposedBy;
        uint256 startTime;
        uint256 endTime;
        address votingStartedBy;
        QuorumMechanism quorumMechanism;
        ProposalType proposalType;
        uint8 priority;
        VotingStatus status;
    }

    struct Votes {
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => uint256) votedTokens;
        address[] voters;
    }

    UnvotedProposal[] public unvotedProposals;
    VotedProposal[] public votedProposals;
    mapping(uint256 => Votes) internal votes;
    mapping(address => bool) internal daoMembers;
    
    uint256 internal daoMembersCount;
    uint256 internal votingPeriodMinutes;

    constructor(
        address _systemToken,
        address _wrapToken,
        address _member1,
        address _member2,
        address _member3
    ) Governor("Fund") GovernorVotes(IVotes(_systemToken)) {
        daoMembers[_member1] = true;
        daoMembers[_member2] = true;
        daoMembers[_member3] = true;
        daoMembersCount += 3;

        votingPeriodMinutes = 5;
        wrapToken = WrapToken(_wrapToken);
        systemToken = SystemToken(_systemToken);
        systemTokensPerVote = 3;
    }

    modifier votedProposalsExists() {
        require(votedProposals.length > 0, "Not found voted proposals");
        _;
    }

    function getMyBalance() public view returns (uint256) {
        if (daoMembers[msg.sender]) {
            return systemToken.balanceOf(msg.sender);
        } else {
            return wrapToken.balanceOf(msg.sender);
        }
    }

    function buyWrapToken() public payable {
        require(msg.value >= 0.01 ether, "Minimal value to buy is 0.01 ether");
        wrapToken.mint(
            msg.sender,
            (msg.value * 10**wrapToken.decimals()) / wrapToken.price()
        );
    }

    function votingDelay() public pure override returns (uint256) {
        return 0; // голосование начинается сразу после выдвижения предложения
    }

    function votingPeriod() public view override returns (uint256) {
        return votingPeriodMinutes * 5; // время голосования в минутах * 5 блоков (1 минута = 5 блоков)
    }

    function proposeBeforeVoting(
        ProposalType _proposalType,
        address _target,
        uint256 _value,
        string memory _calldata,
        string memory _description
    ) public returns (UnvotedProposal memory) {
        require(daoMembers[msg.sender], "Only DAO members can propose");

        bytes4 selector = bytes4(keccak256(bytes(_calldata)));
        bytes memory encodedArgs = abi.encode(_target, _value);
        bytes memory functionCalldata = bytes.concat(selector, encodedArgs);

        UnvotedProposal memory proposal = UnvotedProposal(
            msg.sender,
            _proposalType,
            _target,
            _value,
            functionCalldata,
            _description
        );

        unvotedProposals.push(proposal);
        return proposal;
    }

    function startVoting(
        uint256 _unvotedProposalIndex,
        uint256 _votingMinutes,
        QuorumMechanism _quorumMechanism,
        uint8 _priority
    ) public returns (uint256) {
        UnvotedProposal memory proposal = unvotedProposals[
            _unvotedProposalIndex
        ];
        require(
            _unvotedProposalIndex < unvotedProposals.length,
            "Proposal with this index not exists"
        );
        if (unvotedProposals.length > 1) {
            unvotedProposals[_unvotedProposalIndex] = unvotedProposals[
                unvotedProposals.length - 1
            ];
        }

        unvotedProposals.pop();

        if (
            proposal.proposalType == ProposalType.A ||
            proposal.proposalType == ProposalType.B
        ) {
            require(
                _quorumMechanism == QuorumMechanism.Weighted,
                "Quorum mechanism must be Weighted"
            );
        } else {
            require(
                _quorumMechanism == QuorumMechanism.SimpleMajority ||
                    _quorumMechanism == QuorumMechanism.SuperMajority,
                "Quorum mechanism must be SimpleMajority or SuperMajority"
            );
        }

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = proposal.target;
        values[0] = proposal.value;
        calldatas[0] = proposal.functionCalldata;

        votingPeriodMinutes = _votingMinutes;

        uint256 votedProposalId = super.propose(
            targets,
            values,
            calldatas,
            proposal.description
        );
        uint256 votingStartTime = block.timestamp;
        uint256 votingEndTime = votingStartTime + 60 * _votingMinutes;
        votedProposals.push(
            VotedProposal(
                votedProposalId,
                proposal.proposedBy,
                votingStartTime,
                votingEndTime,
                msg.sender,
                _quorumMechanism,
                proposal.proposalType,
                _priority,
                VotingStatus.Undecided
            )
        );
        return votedProposalId;
    }

    function getVotedProposalData(uint256 _votedProposalId)
        public
        votedProposalsExists
        returns (VotedProposal memory)
    {
        VotedProposal memory proposal;

        for (uint256 i = 0; i < votedProposals.length; i++) {
            if (votedProposals[i].id == _votedProposalId) {
                proposal = votedProposals[i];
                break;
            }
        }

        require(proposal.id != 0, "Proposal not found");
        return proposal;
    }

    function deleteVoting(uint256 _votedProposalId)
        public
        votedProposalsExists
        returns (uint256)
    {
        VotedProposal storage proposal = votedProposals[0];
        bool isProposalFinded;

        for (uint256 i = 0; i < votedProposals.length; i++) {
            if (votedProposals[i].id == _votedProposalId) {
                proposal = votedProposals[i];
                isProposalFinded = true;
                break;
            }
        }

        //TODO: доделать возвращение балансов пользователей, добавить хранение переданных балансов
        proposal.status = VotingStatus.Deleted;
        return proposal.id;
    }

    function vote(
        uint256 _votedProposalId,
        uint8 _support,
        uint256 _amount
    ) public votedProposalsExists returns (uint256) {
        VotedProposal storage proposal = votedProposals[0];
        bool isProposalFinded;

        for (uint256 i = 0; i < votedProposals.length; i++) {
            if (votedProposals[i].id == _votedProposalId) {
                proposal = votedProposals[i];
                isProposalFinded = true;
                break;
            }
        }
        require(isProposalFinded, "Proposal not found");
        require(
            proposal.status != VotingStatus.Deleted &&
                proposal.status != VotingStatus.Decided,
            "Proposal voting not active"
        );

        if (block.timestamp >= proposal.endTime) {
            proposal.status = VotingStatus.Decided;
            return 0;
        }

        // TODO: доделать голосование
        return _amount;
    }

    function quorum(uint256 _votedProposalId)
        public
        view
        override
        votedProposalsExists
        returns (uint256)
    {
        VotedProposal memory proposal;

        for (uint256 i = 0; i < votedProposals.length; i++) {
            if (votedProposals[i].id == _votedProposalId) {
                proposal = votedProposals[i];
                break;
            }
        }

        require(proposal.id != 0, "Proposal not found");

        uint256 totalSupply = systemToken.totalSupply();

        if (proposal.quorumMechanism == QuorumMechanism.SimpleMajority) {
            return daoMembersCount / 2 + 1; // 50% от общего кол-ва участников Dao + 1 голос
        } else if (proposal.quorumMechanism == QuorumMechanism.SuperMajority) {
            return (daoMembersCount / 3) * 2; // 2/3 от кол-ва участников Dao
        } else {
            return totalSupply / 2 + 1 * systemTokensPerVote; // 50% от всех токенов + 1 голос;
        }
    }
}
