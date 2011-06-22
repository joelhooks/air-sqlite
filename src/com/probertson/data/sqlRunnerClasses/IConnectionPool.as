package com.probertson.data.sqlRunnerClasses
{
    import flash.data.SQLConnection;
    import flash.events.SQLErrorEvent;
    import flash.events.SQLEvent;

    public interface IConnectionPool
    {
        function get numConnections():int;

        function get connectionErrorHandler():Function;

        function set connectionErrorHandler(value:Function):void;

        /**
         * Adds a pending statement to the execution queue. If a connection is available
         * it is executed immediately. Otherwise statements are executed in the
         * order they're requested, as database connections become available.
         */
        function addPendingStatement(pendingStatement:IPendingStatement):void;

        /**
         * Requests a blocking connection -- a connection that's guaranteed to be
         * the only one in use at one time. This connection is appropriate to
         * use for executing statements that change data or the database structure,
         * such as <code>INSERT</code>, <code>UPDATE</code>, <code>DELETE</code>,
         * <code>CREATE ...</code>, <code>ALTER ...</code>, <code>DROP ...</code>, etc.
         */
        function addBlockingBatch(batch:IPendingBatch):void;

        function close(handler:Function, errorHandler:Function):void;

        /**
         * Returns a SQLConnection to the pool, indicating that it is no longer
         * being used and can be made available to pending or incoming connection
         * requests.
         *
         * @param    connection    The SQLConnection that is no longer in use.
         */
        function returnConnection(connection:SQLConnection):void;

        function checkPending():void;

        function conn_open(event:SQLEvent):void;

        function conn_openError(event:SQLErrorEvent):void;

        function closeAll():void;

        function conn_close(event:SQLEvent):void;

        function conn_closeError(event:SQLErrorEvent):void;

        function _finishClosing():void;
    }
}