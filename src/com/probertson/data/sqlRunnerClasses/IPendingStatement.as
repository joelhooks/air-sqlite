package com.probertson.data.sqlRunnerClasses
{
    import flash.data.SQLConnection;
    import flash.events.SQLErrorEvent;
    import flash.events.SQLEvent;

    public interface IPendingStatement
    {
        function get statementCache():StatementCache;

        function executeWithConnection(pool:IConnectionPool, conn:SQLConnection):void;

        function stmt_result(event:SQLEvent):void;

        function stmt_error(event:SQLErrorEvent):void;
    }
}