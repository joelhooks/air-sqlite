package com.probertson.data.sqlRunnerClasses
{
    import flash.data.SQLConnection;
    import flash.data.SQLStatement;

    public interface IStatementCache
    {
        function get preferredConnections():Vector.<SQLConnection>;

        function getStatementForConnection(conn:SQLConnection):SQLStatement;
    }
}