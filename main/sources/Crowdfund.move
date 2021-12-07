module Crowdfund::Crowdfund {
    use Std::ASCII;

    // creator creates a dummy struct Foo which is the parameter for Project<T> and Pledge<T>
    struct Project<phantom T, phantom CoinType> {
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
    public(script) fun create_project<T, CoinType>(creator: signer, goal: u64, end_timestamp: u64): Project<T, CoinType> {
    }

    /// Cancel a crowdfund project. Projects can only be canceled before they end.
    public(script) fun cancel_project<T, CoinType>(creator: signer, reason: ASCII::String) {
    }

    /// Claim funds from a funded, ended project.
    public(script) fun claim_project<T, CoinType>(creater: signer) {
    }


    public fun pledge() {}
    public fun cancel_pledge() {}
    public fun reclaim_pledge() {}
}