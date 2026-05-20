-- AlterTable
ALTER TABLE "stored_files" ADD COLUMN     "display_upload_date" TEXT NOT NULL DEFAULT '';
ALTER TABLE "stored_files" ADD COLUMN     "display_upload_time" TEXT NOT NULL DEFAULT '';
