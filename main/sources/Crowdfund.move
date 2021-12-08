module Crowdfund::Crowdfund {
    use Std::ASCII;
    use Std::Signer;
    use Std::Vector;

    const EALREADY_HAS_PROJECT: u64 = 0;
    const EMISSING_PROJECT: u64 = 1;

    // creator creates a dummy struct Foo which is the parameter for Project<T> and Pledge<T>
    struct Project<phantom T, phantom CoinType> has key {
        // TODO: reward_tiers,
        end_timestamp: u64,
        goal: u64,
        pledgers: vector<address>,
    }

    struct Pledge<T, CoinType> {
        project_address: address,
        amount: Coin<CoinType>,
        // TODO: chosen reward
    }

    /// Create a new crowdfund project. The phantom T is a creator provided empty struct.
    public(script) fun create_project<T: drop, CoinType>(creator: signer, goal: u64, end_timestamp: u64, _witness: T) {
        assert!(!exists<Project<T, CoinType>>(Signer::address_of(&creator)), Errors::already_published(EALREADY_HAS_PROJECT));
        move_to(&creator, Project {
            end_timestamp: end_timestamp,
            goal: goal,
            pledgers: Vector::empty(),
        });
    }

    /// Cancel a crowdfund project. Projects can only be canceled before they end.
    public(script) fun cancel_project<T, CoinType>(creator: signer, _reason: ASCII::String) {
        assert!(exists<Project<T, CoinType>>(Signer::address_of(&creator)), Errors::not_published(EMISSING_PROJECT));
        let Project { end_timestamp: _, goal: _, pledgers: _ } = move_from<Project<T, CoinType>>(&creator);
    }

    /// Claim funds from a funded, ended project.
    public(script) fun claim_project<T, CoinType>(creater: signer) {
        assert!(exists<Project<T, CoinType>>(Signer::address_of(&creator)), Errors::not_published(EMISSING_PROJECT));
        let project = move_from<Project<T, CoinType>>(&creator);

    }


    public fun pledge() {}
    public fun cancel_pledge() {}
    public fun reclaim_pledge() {}
}