const Web3 = require('web3');
const rpcURL = "https://alfajores-forno.celo-testnet.org"; // Celo Alfajores Testnet
const web3 = new Web3(rpcURL); // Initialize Web3 with the Celo Testnet RPC URL

// Your wallet address
let myWallet = "0x3199ac028922cc955b80928fc5a4e5d5fd6c6f0e";

// The contract address you're interacting with
let contractAddress = "0xYourContractAddressHere"; // Replace with actual contract address

// The ABI of the contract's balanceOf function
let ABI = [
    {
      "constant": true,
      "inputs": [{"name":"_owner","type":"address"}],
      "name": "balanceOf",
      "outputs": [{"name":"balance","type":"uint256"}],
      "type": "function"
    }
];

async function getBalance() {
    try {
        // Instantiate the contract
        let contract = new web3.eth.Contract(ABI, contractAddress);

        // Call the balanceOf function to get the balance of `myWallet`
        let myBalance = await contract.methods.balanceOf(myWallet).call();

        // Convert the balance from Wei to Ether (since most balances are in Wei)
        let readableBalance = web3.utils.fromWei(myBalance, 'ether');

        console.log('My balance is R', readableBalance);
    } catch (error) {
        console.error('Error getting balance:', error);
    }
}

getBalance();