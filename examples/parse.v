import os
import zztkm.vdotenv

fn main() {
	// loads env vars from a .env file.
	vdotenv.load()

	s3_bucket := os.getenv('S3_BUCKET')
	dynamodb_table := os.getenv('DYNAMODB_TABLE')
	println(s3_bucket)
	println(dynamodb_table)
	// ...
}
