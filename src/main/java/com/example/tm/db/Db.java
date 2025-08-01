package com.example.tm.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Db
{
    private static final String URL =
            System.getenv().getOrDefault("TM_DB_URL",
                    "jdbc:mysql://localhost:3306/task_manager?allowPublicKeyRetrieval=true&useSSL=false&serverTimeZone=UTC");

    private static final String USER = System.getenv("TM_DB_USER");
    private static final String PASS = System.getenv("TM_DB_PASS");

    public static Connection get() throws SQLException
    {
        if (USER == null || PASS == null)
        {
            throw new IllegalStateException("Missing DB Credentials.");
        }
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
