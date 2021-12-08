module Crowdfund::Crowdfund {
    use Std::Errors;
    use Std::Signer;
    use Std::Vector;
    use DiemFramework::DiemTimestamp;

    use NamedAddr::BasicCoin::Coin;
    use NamedAddr::BasicCoin;

    const EALREADY_HAS_PROJECT: u64 = 0;
    const EMISSING_PROJECT: u64 = 1;
    const EALREADY_HAS_PLEDGE: u64 = 2;
    const EMISSING_PLEDGE: u64 = 3;
    const EINSUFFICIENT_DURATION: u64 = 4;
    const EPROJECT_ENDED: u64 = 5;

    const MINIMUM_SECS: u64 = 30 * 24 * 60 * 60; // 1 month

    // creator creates a dummy struct Foo which is the parameter for Project<T> and Pledge<T>
    struct Project<phantom T, phantom CoinType> has key {
        // TODO: reward_tiers,
        end_time_secs: u64,
        goal: u64,
        pledgers: vector<address>,
    }

    struct Pledge<phantom T, phantom CoinType> has key {
        project_address: address,
        amount: Coin<CoinType>,
        // TODO: chosen reward
    }

    /// Create a new crowdfund project. The phantom T is a creator provided empty struct.
    public fun create_project<T: drop, CoinType>(creator: &signer, goal: u64, end_time_secs: u64, _witness: T) {
        assert!(!exists<Project<T, CoinType>>(Signer::address_of(creator)), Errors::already_published(EALREADY_HAS_PROJECT));
        let current_secs = DiemTimestamp::now_seconds();
        assert!(end_time_secs > current_secs + MINIMUM_SECS, Errors::limit_exceeded(EINSUFFICIENT_DURATION));
        move_to(creator, Project<T, CoinType> {
            end_time_secs: end_time_secs,
            goal: goal,
            pledgers: Vector::empty(),
        });
    }

    /// Cancel a crowdfund project. Projects can only be canceled before they end.
    public fun cancel_project<T, CoinType>(creator: &signer, _reason: vector<u8>) acquires Project {
        assert!(exists<Project<T, CoinType>>(Signer::address_of(creator)), Errors::not_published(EMISSING_PROJECT));
        let current_secs = DiemTimestamp::now_seconds();
        let addr = Signer::address_of(creator);
        let project = borrow_global<Project<T, CoinType>>(addr);
        assert!(current_secs < project.end_time_secs, Errors::limit_exceeded(EPROJECT_ENDED));
        let Project { end_time_secs: _, goal: _, pledgers: _ } = move_from<Project<T, CoinType>>(Signer::address_of(creator));
    }

    /// Claim funds from a funded, ended project.
    public fun claim_project<T, CoinType>(creator: &signer) acquires Project {
        assert!(exists<Project<T, CoinType>>(Signer::address_of(creator)), Errors::not_published(EMISSING_PROJECT));
        let Project { end_time_secs: _, goal: _, pledgers: _ } = move_from<Project<T, CoinType>>(Signer::address_of(creator));
    }

    public(script) fun pledge<T, CoinType>(pledger: signer, project_address: address, amount: u64) acquires Project {
        assert!(exists<Project<T, CoinType>>(project_address), Errors::not_published(EMISSING_PROJECT));
        assert!(!exists<Pledge<T, CoinType>>(Signer::address_of(&pledger)), Errors::already_published(EALREADY_HAS_PLEDGE));

        let pledge_amount = BasicCoin::withdraw(&pledger, amount);

        let pledge = Pledge<T, CoinType> {
            project_address: project_address,
            amount: pledge_amount,
        };

        move_to(&pledger, pledge);

        let project = borrow_global_mut<Project<T, CoinType>>(project_address);
        Vector::push_back(&mut project.pledgers, Signer::address_of(&pledger));
    }

    //TODO error conditions
    public(script) fun cancel_pledge<T, CoinType>(pledger: signer) acquires Pledge, Project {
        assert!(exists<Pledge<T, CoinType>>(Signer::address_of(&pledger)), Errors::not_published(EMISSING_PLEDGE));

        let Pledge { project_address, amount } = move_from<Pledge<T, CoinType>>(Signer::address_of(&pledger));

        assert!(exists<Project<T, CoinType>>(project_address), Errors::not_published(EMISSING_PROJECT));

        let project = borrow_global_mut<Project<T, CoinType>>(project_address);

        let (exists, i) = Vector::index_of(&project.pledgers, &Signer::address_of(&pledger));
        assert!(exists, Errors::not_published(EMISSING_PLEDGE));

        Vector::remove(&mut project.pledgers, i);

        BasicCoin::deposit(Signer::address_of(&pledger), amount);
    }
}
