-- CreateEnum
CREATE TYPE "StoredFileType" AS ENUM ('document', 'presentation', 'spreadsheet', 'image');

-- CreateTable
CREATE TABLE "stored_files" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "file_extension" TEXT NOT NULL,
    "file_size" BIGINT NOT NULL,
    "file_type" "StoredFileType" NOT NULL,
    "bucket_name" TEXT NOT NULL,
    "object_key" TEXT NOT NULL,
    "content_type" TEXT NOT NULL,
    "public_url" TEXT,
    "uploaded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stored_files_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stored_files_user_id_idx" ON "stored_files"("user_id");
