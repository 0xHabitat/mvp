export const safeContractUnderTest = () => {
    return !process.env.SAFE_CONTRACT_UNDER_TEST ? "ManagementSystem" : process.env.SAFE_CONTRACT_UNDER_TEST
}