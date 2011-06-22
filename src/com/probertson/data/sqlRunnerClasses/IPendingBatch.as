package com.probertson.data.sqlRunnerClasses
{
    import flash.data.SQLConnection;
    import flash.events.SQLErrorEvent;
    import flash.events.SQLEvent;

    public interface IPendingBatch
    {
        function executeWithConnection(pool:IConnectionPool, connection:SQLConnection):void;

        function beginTransaction():void;

        function conn_begin(event:SQLEvent):void;

        function executeStatements():void;

        function executeNextStatement():void;

        function stmt_result(event:SQLEvent):void;

        function commitTransaction():void;

        function conn_commit(event:SQLEvent):void;

        function finish():void;

        function conn_error(event:SQLErrorEvent):void;

        function rollbackTransaction():void;

        function conn_rollback(event:SQLEvent):void;

        function _finishError():void;

        function callProgressHandler():void;

        function cleanUp():void;
    }
}