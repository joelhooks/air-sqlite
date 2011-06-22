/*
For the latest version of this code, visit:
http://probertson.com/projects/air-sqlite/

Copyright (c) 2009-2011 H. Paul Robertson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
package com.probertson.data
{
    import com.probertson.data.sqlRunnerClasses.ConnectionPool;
    import com.probertson.data.sqlRunnerClasses.IConnectionPool;
    import com.probertson.data.sqlRunnerClasses.IPendingBatch;
    import com.probertson.data.sqlRunnerClasses.IPendingStatement;
    import com.probertson.data.sqlRunnerClasses.PendingBatch;
    import com.probertson.data.sqlRunnerClasses.PendingStatement;
    import com.probertson.data.sqlRunnerClasses.StatementCache;

    import flash.data.SQLStatement;
    import flash.filesystem.File;

    /**
	 * The SQLRunner class executes SQL statements against a database using a
	 * pool of database connections to improve execution speed. SELECT
	 * statements are executed using a pool of connections. Because each
	 * database connection executes in its own thread, this allows multiple
	 * statements to execute at the same time. To optimize query performance,
	 * statement objects are cached and reused when running the same query
	 * multiple times.
	 *
	 * <p>To execute a SELECT statement, call the <code>execute()</code> method.
	 * To execute several SELECT statements, just call <code>execute()</code> multiple
	 * times. The statements will execute in order, using a pool of database
	 * connections.</p>
	 *
	 * <p>To execute an INSERT, UPDATE, or DELETE statement (or several of those
	 * together in a transaction) call the <code>executeModify()</code> method.
	 * If you pass one statement to <code>executeModify()</code>, it runs in its
	 * own transaction. If you pass multiple statements as a batch in one
	 * <code>executeModify()</code> call, they run as a transaction. Either they
	 * all succeed or they are all reverted.</p>
	 *
	 * <p>Here is a basic usage example for a SELECT statement, which is done using the
	 * <code>execute()</code> method:</p>
	 *
	 * <ol>
	 *   <li>Create a File object containing the location of the database file.</li>
	 *   <li>Create the SQLRunner instance</li>
	 *   <li>Call the <code>execute()</code> method, passing in the SQL, an object with parameter values, and the result handler method.</li>
	 * </ol>
	 *
	 * <listing>
	 * // setup code:
	 * // define database file location
	 * var dbFile:File = File.applicationStorageDirectory.resolvePath("myDatabase.db");
	 * // create the SQLRunner
	 * var sqlRunner:SQLRunner = new SQLRunner(dbFile);
	 *
	 * // ...
	 *
	 * // run the statement, passing in one parameter (":employeeId" in the SQL)
	 * // the statement returns an Employee object as defined in the 4th parameter
	 * sqlRunner.execute(LOAD_EMPLOYEE_SQL, {employeeId:102}, resultHandler, Employee);
	 *
	 * private function resultHandler(result:SQLResult):void
	 * {
	 *     var employee:Employee = result.data[0];
	 *     // do something with the employee data
	 * }
	 *
	 * // constant for actual SQL statement text
	 * [Embed(source="sql/LoadEmployee.sql", mimeType="application/octet-stream")]
	 * private static const LoadEmployeeStatementText:Class;
	 * private static const LOAD_EMPLOYEE_SQL:String = new LoadEmployeeStatementText();
	 * </listing>
	 *
	 * <p>Here is a basic example for an INSERT/UPDATE/DELETE statement. To execute those
	 * statements use the executeModify() method. The <code>executeModify()</code> method accepts a
	 * "batch" of statements (a Vector of QueuedStatement objects). If you pass more than
	 * one statement together in a batch, the batch executes as a single transaction.</p>
	 *
	 * <listing>
	 * var insert:QueuedStatement = new QueuedStatement(INSERT_EMPLOYEE_SQL, {firstName:"John", lastName:"Smith"});
	 * var update:QueuedStatement = new QueuedStatement(UPDATE_EMPLOYEE_SALARY_SQL, {employeeId:100, salary:1000});
	 * var statementBatch:Vector.&lt;QueuedStatement&gt; = Vector.&lt;QueuedStatement&gt;([insert, update]);
	 *
	 * sqlRunner.executeModify(statementBatch, resultHandler, errorHandler, progressHandler);
	 *
	 * private function resultHandler(results:Vector.&lt;SQLResult&gt;):void
	 * {
	 *      // all operations done
	 * }
	 *
	 * private function errorHandler(error:SQLError):void
	 * {
	 *     // something went wrong
	 * }
	 *
	 * private function progressHandler(numStepsComplete:uint, totalSteps:uint):void
	 * {
	 *     var progressPercent:int = numStepsComplete / totalSteps;
	 * }
	 *
	 * // constants for actual SQL statement text
	 * [Embed(source="sql/InsertEmployee.sql", mimeType="application/octet-stream")]
	 * private static const InsertEmployeeStatementText:Class;
	 * private static const INSERT_EMPLOYEE_SQL:String = new InsertEmployeeStatementText();
	 *
	 * [Embed(source="sql/UpdateEmployeeSalary.sql", mimeType="application/octet-stream")]
	 * private static const UpdateEmployeeSalaryStatementText:Class;
	 * private static const UPDATE_EMPLOYEE_SALARY_SQL:String = new UpdateEmployeeSalaryStatementText();
	 * </listing>
	 */
	public class SQLRunner implements ISQLRunner
    {
		// ------- Constructor -------

		/**
		 * Creates a SQLRunner instance.
		 *
		 * @param databaseFile The file location of the database. If a database doesn't
		 * 					   exist at that location it is created.
		 * @param maxPoolSize The maximum number of SQLConnection instances to
		 * 					  use to execute SELECT statements. More connections
		 * 					  in the pool means more statements execute at the
		 * 					  same time, which increases speed but also increases
		 * 					  memory and processor use. The default pool size is 5.
		 */
		public function SQLRunner(databaseFile:File, maxPoolSize:int=5)
		{
			_connectionPool = new ConnectionPool(databaseFile, maxPoolSize);
			// create this cache object ahead of time to avoid the overhead
			// of checking if it's null each time execute() is called.
			// Other cache objects won't be needed nearly as much, so
			// their instantiation can be deferred.
			_stmtCache = new Object();
		}


		// ------- Member vars -------

		private var _connectionPool:IConnectionPool;
		private var _stmtCache:Object;
		private var _batchStmtCache:Object;


		// ------- Public properties -------

        public function get numConnections():int
        {
            return _connectionPool.numConnections;
        }


        public function get connectionErrorHandler():Function
        {
            return _connectionPool.connectionErrorHandler;
        }

        public function set connectionErrorHandler(value:Function):void
        {
            _connectionPool.connectionErrorHandler = value;
        }


        // ------- Public methods -------

        public function execute(sql:String, parameters:Object, handler:Function, itemClass:Class = null, errorHandler:Function = null):void
        {
            var stmt:StatementCache = _stmtCache[sql];
            if (stmt == null)
            {
                stmt = new StatementCache(sql);
                _stmtCache[sql] = stmt;
            }
            var pending:IPendingStatement = new PendingStatement(stmt, parameters, handler, itemClass, errorHandler);
            _connectionPool.addPendingStatement(pending);
        }


        public function executeModify(statementBatch:Vector.<QueuedStatement>, resultHandler:Function, errorHandler:Function, progressHandler:Function = null):void
        {
            var len:int = statementBatch.length;
            var statements:Vector.<SQLStatement> = new Vector.<SQLStatement>(len);
            var parameters:Vector.<Object> = new Vector.<Object>(len);

            if (_batchStmtCache == null)
            {
                _batchStmtCache = new Object();
            }

            for (var i:int = 0; i < len; i++)
            {
                var sql:String = statementBatch[i].statementText;
                var stmt:SQLStatement = _batchStmtCache[sql];
                if (stmt == null)
                {
                    stmt = new SQLStatement();
                    stmt.text = sql;
                    _batchStmtCache[sql] = stmt;
                }

                statements[i] = stmt;
                parameters[i] = statementBatch[i].parameters;
            }

            var pendingBatch:IPendingBatch = new PendingBatch(statements, parameters, resultHandler, errorHandler, progressHandler);
            _connectionPool.addBlockingBatch(pendingBatch);
        }


        public function close(resultHandler:Function, errorHandler:Function = null):void
        {
            _connectionPool.close(resultHandler, errorHandler);
        }
    }
}