package com.example.tm;

import com.example.tm.db.Db;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class App
{
    public static void main (String[] args)
    {
        System.out.println("Attempting to connect to MYSQL...");

        String sql = "SELECT VERSION() AS ver, CURRENT_USER() AS user";

        try (Connection c = Db.get();
        PreparedStatement ps = c.prepareStatement(sql);
        ResultSet rs = ps.executeQuery())
        {
            if (rs.next())
            {
                System.out.println("Version: "+rs.getString("ver")+" | As: " + rs.getString("user"));
            }


      String members = """
        SELECT p.name AS project, u.full_name AS member, r.name AS role_name
        FROM project_memberships pm
        JOIN projects p ON p.id = pm.project_id
        JOIN users u ON u.id = pm.user_id
        JOIN project_roles r ON r.id = pm.role_id
        ORDER BY p.name, role_name, member
      """;
      try (PreparedStatement ps2 = c.prepareStatement(members);
           ResultSet rs2 = ps2.executeQuery()) {
        System.out.println("Members by project:");
        while (rs2.next()) {
          System.out.printf(" - %s | %s | %s%n",
              rs2.getString("project"),
              rs2.getString("member"),
              rs2.getString("role_name"));
        }
      }

        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("\nCheck:\n" +
                    "1) IntelliJ Run Config has TM_DB_USER/TM_DB_PASS set.\n" +
                    "2) MySQL is running; URL host/port/schema correct.\n" +
                    "3) User has privileges on task_manager.\n");
        }
    }
}

