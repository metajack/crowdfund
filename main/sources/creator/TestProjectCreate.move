module Sender::TestProjectCreate {
    use Sender::Crowdfund;

    struct ConesOfDunshireGame has drop, store {}

    public(script) fun create_project<CoinType>(account: signer, goal: u64, end_time_secs: u64) {
        Crowdfund::create_project<ConesOfDunshireGame, CoinType>(&account, goal, end_time_secs, ConesOfDunshireGame {});
    }
}

