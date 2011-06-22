package com.probertson.data
{
    import flash.events.SQLErrorEvent;
    import flash.events.SQLEvent;

    public interface ISQLRunnerUnpooled
    {
        /**
         * Executes a SQL SELECT query asynchronously. If a SQLConnection is
         * available, the query begins executing immediately. Otherwise, it is added to
         * a queue of pending queries that are executed in request order.
         *
         * @param    sql    The text of the SQL statement to execute.
         * @param    parameters    An object whose properties contain the values of the parameters
         *                         that are used in executing the SQL statement.
         * @param    responder    The responder containing the callback functions that are called when the statement execution
         *                         finishes (or fails). Both functions are optional. The responder's result function should define one parameter, a SQLResult
         *                         object. When the statement is executed, the SQLResult object containing
         *                         the results of the statement execution is passed to this function. The responder's
         *                         status function should define one parameter, a SQLError object.
         * @param    itemClass    A class that has properties corresponding to the columns in the
         *                         SELECT statement. In the resulting data set, each
         *                         result row is represented as an instance of this class.
         *
         * @see Responder
         */
        function execute(sql:String, parameters:Object, responder:Responder, itemClass:Class = null):void;

        /**
         * Waits until all pending statements execute, then closes all open connections to
         * the database.
         *
         * @param    resultHandler    A function that's called when connections are closed.
         *                             No argument values are passed to the function.
         */
        function close(resultHandler:Function):void;

        function checkPending():void;

        function conn_open(event:SQLEvent):void;

        function stmt_result(event:SQLEvent):void;

        function stmt_error(event:SQLErrorEvent):void;

        function conn_close(event:SQLEvent):void;

        function returnConnection():void;
    }
}