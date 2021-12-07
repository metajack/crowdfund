module @Crowdfund::Crowdfund {
    // creator creates a dummy struct Foo which is the parameter for Project<T> and Pledge<T>
    struct Project<T, phantom CoinType> {
        // TODO: reward_tiers,
        end_timestamp,
        goal,
        pledgers: vector<address>,
    }

    struct Pledge<T, CoinType> {
        project_address: address,
        amount: Coin<CoinType>,
        // TODO: chosen reward
    }

    public fun create_project() {}
    public fun cancel_project() {}
    public fun claim_project() {}


    public fun pledge() {}
    public fun cancel_pledge() {}
    public fun reclaim_pledge() {}
}