import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;

public class DbSchemaDump {
    public static void main(String[] args) throws Exception {
        String url = "jdbc:h2:file:./data/projectxdb;MODE=Oracle;DB_CLOSE_DELAY=-1;AUTO_SERVER=TRUE;DB_CLOSE_ON_EXIT=TRUE";
        try (Connection conn = DriverManager.getConnection(url, "sa", "")) {
            DatabaseMetaData meta = conn.getMetaData();
            try (ResultSet tables = meta.getTables(null, "PUBLIC", "%", new String[] { "TABLE" })) {
                while (tables.next()) {
                    String table = tables.getString("TABLE_NAME");
                    System.out.println("TABLE " + table);

                    TreeSet<String> pkColumns = new TreeSet<>();
                    try (ResultSet pk = meta.getPrimaryKeys(null, "PUBLIC", table)) {
                        while (pk.next()) {
                            pkColumns.add(pk.getString("COLUMN_NAME"));
                        }
                    }

                    Map<Integer, String> columnLines = new TreeMap<>();
                    try (ResultSet cols = meta.getColumns(null, "PUBLIC", table, "%")) {
                        while (cols.next()) {
                            int ordinal = cols.getInt("ORDINAL_POSITION");
                            String name = cols.getString("COLUMN_NAME");
                            String type = cols.getString("TYPE_NAME");
                            int size = cols.getInt("COLUMN_SIZE");
                            String nullable = cols.getInt("NULLABLE") == DatabaseMetaData.columnNoNulls ? "NOT NULL" : "NULL";
                            String pkMark = pkColumns.contains(name) ? " PK" : "";
                            columnLines.put(ordinal, "  - " + name + " : " + type + "(" + size + ")" + " " + nullable + pkMark);
                        }
                    }

                    for (String line : columnLines.values()) {
                        System.out.println(line);
                    }

                    try (ResultSet fk = meta.getImportedKeys(null, "PUBLIC", table)) {
                        while (fk.next()) {
                            String fkColumn = fk.getString("FKCOLUMN_NAME");
                            String pkTable = fk.getString("PKTABLE_NAME");
                            String pkColumn = fk.getString("PKCOLUMN_NAME");
                            System.out.println("  -> FK " + fkColumn + " -> " + pkTable + "." + pkColumn);
                        }
                    }
                    System.out.println();
                }
            }
        }
    }
}
