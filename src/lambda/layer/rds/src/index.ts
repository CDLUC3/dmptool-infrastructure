import * as mysql from 'mysql2/promise';
import { formatISO9075, isDate } from "date-fns";

// Get the table names from the ENV
const DATABASE_HOST = process.env.RDS_HOST ?? 'localhost';
const DATABASE_PORT = Number.parseInt(process.env.RDS_PORT) ?? 3306;
const DATABASE_NAME = process.env.RDS_DATABASE ?? 'dmp';
const DATABASE_USER = process.env.RDS_USER ?? 'root';
const DATABASE_PASSWORD = process.env.RDS_PASSWORD ?? 'password';

// Create a connection to the MySQL database
const createConnection = async (): Promise<mysql.Connection> => {
  const args = {
    host: DATABASE_HOST,
    port: DATABASE_PORT,
    user: DATABASE_USER,
    password: DATABASE_PASSWORD,
    database: DATABASE_NAME,
    multipleStatements: false,
  }

  console.log(args);

  return await mysql.createConnection(args);
};

// Convert incoming value to appropriate type for insertion into a SQL query
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const prepareValue = (val: any, type: any): any => {
  if (val === null || val === undefined) {
    return null;
  }
  switch (type) {
    case 'number':
      return Number(val);
    case 'json':
      return JSON.stringify(val);
    case Object:
    case Array:
      return JSON.stringify(val);
    case 'boolean':
      return Boolean(val);
    default:
      if (isDate(val)) {
        const date = new Date(val).toISOString();
        return formatISO9075(date);

      } else if (Array.isArray(val)) {
        return JSON.stringify(val);

      } else {
        return String(val);
      }
  }
}

// Runs the provided SQL query and returns the results
export const queryTable = async (
  query: string,
  params: any[] = []
): Promise<{ results: any[], fields: any[] }> => {
  const connection = await createConnection();

  // Remove all tabs and new lines
  const sql = query.split(/[\s\t\n]+/).join(' ');
  // Prepare the values for the query
  const vals = params.map((val) => prepareValue(val, typeof val));

  // Run the query
  const [results, fields] = await connection.query(sql, vals);
  connection.end();

  return { results: results as any[], fields: fields as any[] };
};
