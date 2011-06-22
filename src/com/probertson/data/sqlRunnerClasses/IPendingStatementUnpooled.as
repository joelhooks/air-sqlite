package com.probertson.data.sqlRunnerClasses
{
    import com.probertson.data.Responder;

    public interface IPendingStatementUnpooled
    {
        function get sql():String;

        function get parameters():Object;

        function get responder():Responder;

        function get itemClass():Class;
    }
}