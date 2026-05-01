-- CreateTable
CREATE TABLE "objectives" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "is_completed" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "objectives_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "objectives_user_id_idx" ON "objectives"("user_id");
