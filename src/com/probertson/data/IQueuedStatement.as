package com.probertson.data
{
    public interface IQueuedStatement
    {
        /**
         * The SQL text of the statement to execute
         */
        function get statementText():String;

        /**
         * An object (associative array) containing the names and values of the
         * parameters used in the statement.
         */
        function get parameters():Object;
    }
}