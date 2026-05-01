-- CreateTable
CREATE TABLE "mindmaps" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "idea_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mindmaps_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "mindmaps_user_id_idx" ON "mindmaps"("user_id");

-- CreateIndex
CREATE INDEX "mindmaps_user_id_idea_id_idx" ON "mindmaps"("user_id", "idea_id");
