module Sender::Crowdfund {
    use Std::Errors;
    use Std::Signer;
    use Std::Vector;
    use DiemFramework::DiemTimestamp;

    use Sender::BasicCoin::Coin;
    use Sender::BasicCoin;

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
    /// This is not a script function because of the witness.
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
    public(script) fun cancel_project<T, CoinType>(creator: signer, _reason: vector<u8>) acquires Project, Pledge {
        let creator_addr = Signer::address_of(&creator);
        assert!(exists<Project<T, CoinType>>(creator_addr), Errors::not_published(EMISSING_PROJECT));
        let current_secs = DiemTimestamp::now_seconds();
        let project = borrow_global<Project<T, CoinType>>(creator_addr);
        assert!(current_secs < project.end_time_secs, Errors::limit_exceeded(EPROJECT_ENDED));
        let project = move_from<Project<T, CoinType>>(creator_addr);
        return_funds(project);
    }

    /// Claim funds from a funded, ended project.
    public(script) fun claim_project<T, CoinType>(creator: signer) acquires Project, Pledge {
        let creator_addr = Signer::address_of(&creator);
        assert!(exists<Project<T, CoinType>>(creator_addr), Errors::not_published(EMISSING_PROJECT));

        let project = move_from<Project<T, CoinType>>(creator_addr);
        assert!(project_has_ended(&project), Errors::limit_exceeded(EINSUFFICIENT_DURATION));

        let fund_amount = amount_funded(&project);


        // If goal was met, take all the funds
        if (fund_amount >= project.goal) {
            let Project { end_time_secs: _, goal: _, pledgers } = project;

            let i = 0;
            let len = Vector::length(&pledgers);

            while (i < len) {
                let addr = Vector::borrow(&pledgers, i);
                let Pledge { project_address: _, amount } = move_from<Pledge<T, CoinType>>(*addr);
                BasicCoin::deposit(creator_addr, amount);

                i = i + 1;
            };
        } else {
            // Otherwise return fund
            return_funds(project);
        };
    }

    public fun return_funds<T, CoinType>(project: Project<T, CoinType>) acquires Pledge {
        let Project { end_time_secs: _, goal: _, pledgers } = project;

        let i = 0;
        let len = Vector::length(&pledgers);

        while (i < len) {
            let addr = Vector::borrow(&pledgers, i);
            let Pledge { project_address: _, amount } = move_from<Pledge<T, CoinType>>(*addr);
            BasicCoin::deposit(*addr, amount);

            i = i + 1;
        };
    }

    /// Returns whether a Project has ended
    public fun project_has_ended<T, CoinType>(project: &Project<T, CoinType>): bool {
        let current_secs = DiemTimestamp::now_seconds();
        current_secs < project.end_time_secs
    }

    /// Current funding level of a project
    public fun amount_funded<T, CoinType>(project: &Project<T, CoinType>): u64 acquires Pledge {
        let fund_amount = 0;
        let i = 0;
        let len = Vector::length(&project.pledgers);

        while (i < len) {
            
            let addr = Vector::borrow(&project.pledgers, i);
            let pledge = borrow_global<Pledge<T, CoinType>>(*addr);

            fund_amount = fund_amount + BasicCoin::value(&pledge.amount);

            i = i + 1;
        };

        fund_amount
    }

    /// Pledge to a Project
    public(script) fun pledge<T, CoinType>(pledger: signer, project_address: address, amount: u64) acquires Project {
        assert!(exists<Project<T, CoinType>>(project_address), Errors::not_published(EMISSING_PROJECT));
        assert!(!exists<Pledge<T, CoinType>>(Signer::address_of(&pledger)), Errors::already_published(EALREADY_HAS_PLEDGE));

        let project = borrow_global_mut<Project<T, CoinType>>(project_address);

        assert!(!project_has_ended(project), Errors::limit_exceeded(EPROJECT_ENDED));

        let pledge_amount = BasicCoin::withdraw(&pledger, amount);

        let pledge = Pledge<T, CoinType> {
            project_address: project_address,
            amount: pledge_amount,
        };

        move_to(&pledger, pledge);

        Vector::push_back(&mut project.pledgers, Signer::address_of(&pledger));
    }

    //TODO error conditions
    public(script) fun cancel_pledge<T, CoinType>(pledger: signer) acquires Pledge, Project {
        assert!(exists<Pledge<T, CoinType>>(Signer::address_of(&pledger)), Errors::not_published(EMISSING_PLEDGE));

        let Pledge { project_address, amount } = move_from<Pledge<T, CoinType>>(Signer::address_of(&pledger));

        assert!(exists<Project<T, CoinType>>(project_address), Errors::not_published(EMISSING_PROJECT));

        let project = borrow_global_mut<Project<T, CoinType>>(project_address);

        // Check to see if the user can pull their money out
        if (project_has_ended(project)) {
            // The project has ended and the goal hasn't been met
            assert!(project.goal > amount_funded(project), Errors::limit_exceeded(EINSUFFICIENT_DURATION));
        } else {
            // No additional checks, you can just pull your money out
        };

        let (exists, i) = Vector::index_of(&project.pledgers, &Signer::address_of(&pledger));
        assert!(exists, Errors::not_published(EMISSING_PLEDGE));

        Vector::remove(&mut project.pledgers, i);

        BasicCoin::deposit(Signer::address_of(&pledger), amount);
    }
}
