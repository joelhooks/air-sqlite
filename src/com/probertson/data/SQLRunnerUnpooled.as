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
    import com.probertson.data.sqlRunnerClasses.IPendingStatementUnpooled;
    import com.probertson.data.sqlRunnerClasses.PendingStatementUnpooled;

    import flash.data.SQLConnection;
    import flash.data.SQLResult;
    import flash.data.SQLStatement;
    import flash.events.SQLErrorEvent;
    import flash.events.SQLEvent;
    import flash.filesystem.File;

    /**
	 * The SQLRunnerUnpooled class executes SQL statements against a database.
	 * Unlike with the SQLRunner class, the SQLRunnerUnpooled class only uses
	 * one SQLConnection instance for all operations including SELECT
	 * statements. This minimizes the memory and processor footprint although
	 * it increases the delay when executing multiple statements at the same time.
	 * The SQLRunnerUnpooled class is intended to be used in situations where memory
	 * and processor power are limited, such as with mobile devices.
	 *
	 * <p>To execute a statement, call the <code>execute()</code> method.</p>
	 *
	 * @see SQLRunner
	 */
	public class SQLRunnerUnpooled implements ISQLRunnerUnpooled
    {
		/**
		 * Creates a SQLRunnerUnpooled instance.
		 *
		 * @param databaseFile	The database to use for executing statements.
		 */
		public function SQLRunnerUnpooled(databaseFile:File)
		{
			_conn = new SQLConnection();
			_conn.addEventListener(SQLEvent.OPEN, conn_open);
			_conn.openAsync(databaseFile);
			_inUse = true;

			// create objects ahead of time to avoid the overhead
			// of checking if they're null each time execute() is called.
			// Other cache objects won't be needed nearly as much, so
			// their instantiation can be deferred.
			_pending = new Vector.<IPendingStatementUnpooled>();
			_cache = new Object();
		}


		// ------- Member vars -------

		private var _conn:SQLConnection;
		private var _inUse:Boolean;
		private var _cache:Object;
		private var _current:IPendingStatementUnpooled;
		private var _pending:Vector.<IPendingStatementUnpooled>;
		private var _closeHandler:Function;
		//private var _batchStmtCache:Object;


		// ------- Public methods -------

        public function execute(sql:String, parameters:Object, responder:Responder, itemClass:Class = null):void
        {
            var stmtData:PendingStatementUnpooled = new PendingStatementUnpooled(sql, parameters, responder, itemClass);

            _pending[_pending.length] = stmtData;

            checkPending();
        }


        public function close(resultHandler:Function):void
        {
            _closeHandler = resultHandler;
            checkPending();
        }


        // ------- Pending statements -------
        public function checkPending():void
        {
            // standard (read-only) statements
            if (_pending.length > 0)
            {
                if (!_inUse)
                {
                    _current = _pending.shift();

                    var stmt:SQLStatement = _cache[_current.sql];
                    if (stmt == null)
                    {
                        stmt = new SQLStatement();
                        stmt.sqlConnection = _conn;
                        stmt.text = _current.sql;
                        _cache[_current.sql] = stmt;
                    }

                    stmt.addEventListener(SQLEvent.RESULT, stmt_result);
                    stmt.addEventListener(SQLErrorEvent.ERROR, stmt_error);

                    if (_current.itemClass != null)
                    {
                        stmt.itemClass = _current.itemClass;
                    }

                    stmt.clearParameters();
                    if (_current.parameters != null)
                    {
                        for (var prop:String in _current.parameters)
                        {
                            stmt.parameters[":" + prop] = _current.parameters[prop];
                        }
                    }

                    stmt.execute();

                    _inUse = true;
                    return;
                }
                else
                {
                    // The connection isn't available
                    return;
                }
            }

            // if there aren't any pending requests and there is a pending close
            // request, close the connections
            if (_closeHandler != null)
            {
                _conn.addEventListener(SQLEvent.CLOSE, conn_close);
                _conn.close();
            }
        }


        // ------- Event handling -------

        public function conn_open(event:SQLEvent):void
        {
            _conn.removeEventListener(SQLEvent.OPEN, conn_open);
            returnConnection();
        }


        public function stmt_result(event:SQLEvent):void
        {
            var stmt:SQLStatement = event.target as SQLStatement;
            stmt.removeEventListener(SQLEvent.RESULT, stmt_result);
            stmt.removeEventListener(SQLErrorEvent.ERROR, stmt_error);
            var result:SQLResult = stmt.getResult();
            if (_current.responder.result != null)
            {
                _current.responder.result(result);
            }
            returnConnection();
        }


        public function stmt_error(event:SQLErrorEvent):void
        {
            var stmt:SQLStatement = event.target as SQLStatement;
            stmt.removeEventListener(SQLEvent.RESULT, stmt_result);
            stmt.removeEventListener(SQLErrorEvent.ERROR, stmt_error);
            if (_current.responder.error != null)
            {
                _current.responder.error(event.error);
            }
            returnConnection();
        }


        public function conn_close(event:SQLEvent):void
        {
            _conn.removeEventListener(SQLEvent.CLOSE, conn_close);

            _closeHandler();

            _closeHandler = null;
        }


        // ------- Private methods -------

        public function returnConnection():void
        {
            _inUse = false;
            checkPending();
        }
    }
}