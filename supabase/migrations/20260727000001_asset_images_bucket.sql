-- Private bucket for user-uploaded asset photos and receipts.
-- Path convention: {household_id}/{asset_id}/photo.jpg | receipt.jpg
-- Deterministic paths mean no extra DB columns are needed — both partners
-- resolve the same files, and replacing an image is an overwrite (upsert).
insert into storage.buckets (id, name, public)
values ('asset-images', 'asset-images', false)
on conflict (id) do nothing;

-- Household members can read/write images under their household's folder.
create policy "asset_images_member_read"
on storage.objects for select using (
  bucket_id = 'asset-images'
  and (storage.foldername(name))[1]::uuid in (
    select household_id from household_members where user_id = auth.uid()
  )
);

create policy "asset_images_member_insert"
on storage.objects for insert with check (
  bucket_id = 'asset-images'
  and (storage.foldername(name))[1]::uuid in (
    select household_id from household_members where user_id = auth.uid()
  )
);

create policy "asset_images_member_update"
on storage.objects for update using (
  bucket_id = 'asset-images'
  and (storage.foldername(name))[1]::uuid in (
    select household_id from household_members where user_id = auth.uid()
  )
);

create policy "asset_images_member_delete"
on storage.objects for delete using (
  bucket_id = 'asset-images'
  and (storage.foldername(name))[1]::uuid in (
    select household_id from household_members where user_id = auth.uid()
  )
);
