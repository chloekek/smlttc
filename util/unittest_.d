module util.unittest_;

@system
shared static this()
{
    import core.runtime : Runtime, runModuleUnitTests;
    import util.os      : getenv;
    if (getenv("UNITTEST") == "Y") {
        Runtime.extendedModuleUnitTester = function() {
            Runtime.extendedModuleUnitTester = null;
            auto result = runModuleUnitTests();
            result.runMain = false;
            return result;
        };
    } else {
        Runtime.moduleUnitTester = function() {
            return true;
        };
    }
}
