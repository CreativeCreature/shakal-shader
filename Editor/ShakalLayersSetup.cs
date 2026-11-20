using UnityEditor;
using UnityEngine;

[InitializeOnLoad]
public static class ShakalLayerSetup
{
    const string LayerName = "ShakalEffect";

    static ShakalLayerSetup()
    {
        EditorApplication.delayCall += EnsureLayer;
    }

    static void EnsureLayer()
    {
        if (LayerMask.NameToLayer(LayerName) != -1)
        {
            return;
        }

        var asset = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset");
        if (asset == null || asset.Length == 0) return;

        var tagManager = new SerializedObject(asset[0]);
        var layers = tagManager.FindProperty("layers");

        for (int i = 8; i < 32; i++)
        {
            var slot = layers.GetArrayElementAtIndex(i);
            if (string.IsNullOrEmpty(slot.stringValue))
            {
                slot.stringValue = LayerName;
                tagManager.ApplyModifiedProperties();
                Debug.Log($"Создан слой '{LayerName}' (индекс {i}). Скрипт настройки удалён.");
                return;
            }
        }

        // Если свободных слотов нет, скрипт НЕ удаляется, чтобы повторить попытку, 
        // когда вы освободите место и перекомпилируете проект
        Debug.LogWarning($"Нет свободных слоёв для '{LayerName}'. Создайте его вручную.");
    }
}
