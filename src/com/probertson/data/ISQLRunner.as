package com.probertson.data
{
import com.probertson.data.QueuedStatement;import com.probertson.data.SQLRunner;import com.probertson.data.sqlRunnerClasses.PendingBatch;import com.probertson.data.sqlRunnerClasses.PendingStatement;import com.probertson.data.sqlRunnerClasses.StatementCache;import flash.data.SQLStatement;
    public interface ISQLRunner
    {
        /**
         * The total number of database connections currently created. This
         * includes connections in the pool (waiting to be used) as well as
         * connections that are currently in use.
         */
        function get numConnections():int;

        /**
         * Set this property to specify a function that is called when an error happens
         * while attempting to open a database connection.
         *
         * <p>When an error occurs while trying to connect to a database, the specified function is
         * called with one argument, the SQLError object for the error. If no function
         * is specified for this property, the error is thrown, resulting in an
         * unhandled error in a debugger environment.</p>
         */
        function get connectionErrorHandler():Function;

        function set connectionErrorHandler(value:Function):void;

        /**
         * Executes a SQL SELECT query asynchronously. If a SQLConnection is
         * available, the query begins executing immediately. Otherwise, it is added to
         * a queue of pending queries that are executed in request order.
         *
         * <p>To execute several SELECT statements, just call <code>execute()</code> multiple
         * times. The statements will execute in order, using the pool of database
         * connections.</p>
         *
         * @param    sql    The text of the SQL statement to execute.
         * @param    parameters    An object whose properties contain the values of the parameters
         *                         that are used in executing the SQL statement.
         * @param    handler    The callback function that's called when the statement execution
         *                     finishes. This function should define one parameter, a SQLResult
         *                     object. When the statement is executed, the SQLResult object containing
         *                     the results of the statement execution is passed to this function.
         * @param    itemClass    A class that has properties corresponding to the columns in the
         *                         SELECT statement. In the resulting data set, each
         *                         result row is represented as an instance of this class.
         * @param    errorHandler    The callback function that's called when an error occurs
         *                             during the statement's execution. A single argument is passed
         *                             to the errorHandler function: a SQLError object containing
         *                             information about the error that happened.
         */
        function execute(sql:String, parameters:Object, handler:Function, itemClass:Class = null, errorHandler:Function = null):void;

        /**
         * Executes one or more "data modification" statements (INSERT, UPDATE, and
         * DELETE statements). Multiple statements can be passed as a batch, in which case
         * the statements are executed within a transaction.
         *
         * <p>If you pass one statement (a Vector with only one element) to
         * the <code>executeModify()</code> method, it runs in its
         * own transaction. If you pass multiple statements as a batch in one
         * <code>executeModify()</code> call, they run as a transaction. Either they
         * all succeed or they are all reverted.</p>
         *
         * <p>The <code>executeModify()</code> method isn't meant to run SELECT statements.
         * If you want to run several SELECT statements at the same time, just call
         * the <code>execute()</code> method multiple times, once per statement. If you
         * want to run one or more INSERT or UPDATE statements (for example) and
         * then run a SELECT statement immediately after those statements finish,
         * call <code>executeModify()</code> with the INSERT/UPDATE statements
         * and then call <code>execute()</code> with the SELECT statement. (You
         * don't need to wait for the <code>executeModify()</code> result before
         * calling <code>execute()</code>. The statements will run in the order
         * they're called, with the INSERT/UPDATE transaction first and the
         * SELECT statement afterward.)</p>
         *
         * @param    batch    The set of SQL statements to execute, defined as QueuedStatement
         *                     objects.
         * @param    resultHandler    The function that's called when the batch processing finishes.
         *                             This function is called with one argument, a Vector of
         *                             SQLResult objects returned by the batch operations.
         * @param    errorHandler    The function that's called when an error occurs in the batch.
         *                             The function is called with one argument, a SQLError object.
         * @param    progressHandler    A function that's called each time progress is made in executing
         *                             the batch (including after opening the transaction and after
         *                             each statement execution). This function is called with two
         *                             uint arguments: The number of steps completed,
         *                             and the total number of execution steps. (Each "step" is either
         *                             a statement to be executed, or the opening or closing of the
         *                             transaction.)
         */
        function executeModify(statementBatch:Vector.<QueuedStatement>, resultHandler:Function, errorHandler:Function, progressHandler:Function = null):void;

        /**
         * Waits until all pending statements execute, then closes all open connections to
         * the database.
         *
         * <p>Once you've called <code>close()</code>, you shouldn't use the SQLRunner
         * instance anymore. Instead, create a new SQLRunner object if you need to
         * access the same database again.</p>
         *
         * @param    resultHandler    A function that's called when connections are closed.
         *                             No argument values are passed to the function.
         *
         * @param    errorHandler    A function that's called when an error occurs during
         *                             the close operation. A SQLError object is passed as
         *                             an argument to the function.
         */
        function close(resultHandler:Function, errorHandler:Function = null):void;
    }
}