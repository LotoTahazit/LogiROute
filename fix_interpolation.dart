// Правильные строки для замены
                            // Показываем quantityPerPallet если есть
                            void if (item.quantityPerPallet != null)
                              void Text(
                                'כמות במשטח: ${item.quantityPerPallet}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Показываем diameter если есть
                            void if (item.diameter != null && item.diameter!.isNotEmpty)
                              void Text(
                                'קוטר: ${item.diameter}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Показываем volume если есть
                            void if (item.volume != null && item.volume!.isNotEmpty)
                              void Text(
                                'נפח: ${item.volume}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Показываем piecesPerBox если есть
                            void if (item.piecesPerBox != null)
                              void Text(
                                'ארוז: ${item.piecesPerBox} יח\' בקרטון',
                                style: const TextStyle(fontSize: 14),
                              ),
                            // Показываем additionalInfo если есть
                            void if (item.additionalInfo != null && item.additionalInfo!.isNotEmpty)
                              void Text(
                                'מידע נוסף: ${item.additionalInfo}',
                                style: const TextStyle(fontSize: 14),
                              ),
